import Foundation
import AppKit
import Carbon.HIToolbox
import ImageIO
import SwiftUI
import SwiftData
import StoreKit

@MainActor
@Observable
final class AppViewModel {

    let settings = AppSettings()
    let clipboardWatcher = ClipboardWatcher()
    let folderWatcher = FolderWatcher()
    let overlayService = OverlayService()
    let dropZoneService = DropZoneService()
    let ignoreCache = IgnoreCache()
    let tipStore = TipStore()
    let processingCoordinator = ProcessingCoordinator()
    let hotkeyCoordinator = HotkeyCoordinator()
    let contextAwareService = ContextAwareService()

    private(set) var events: [OptimizationEvent] = []
    private(set) var totalSaved: Int = 0
    private(set) var totalOptimized: Int = 0

    var isProcessing: Bool { processingCoordinator.isProcessing }
    var lastError: String? { processingCoordinator.lastError }
    var lastOriginalData: Data? { processingCoordinator.lastOriginalData }
    var lastOptimizedData: Data? { processingCoordinator.lastOptimizedData }
    var lastOptimizedFormat: ImageFormat { processingCoordinator.lastOptimizedFormat }
    var lastOriginalFormat: ImageFormat { processingCoordinator.lastOriginalFormat }
    var lastSourceAppBundleID: String { processingCoordinator.lastSourceAppBundleID }

    private let notificationService = NotificationService.shared
    private let log = Logger.shared

    private var onboardingWindow: NSWindow?
    private var onboardingCloseObserver: NSObjectProtocol?
    private var frontmostAppObserver: NSObjectProtocol?
    private var hasStartedServices = false
    private var lastKnownFrontmostBundleID: String = ""
    private var hasSetupClipboardWatcher = false
    private var hasSetupFolderWatcher = false
    private var hasSetupOverlayActions = false
    private var hasSetupDropZoneActions = false
    private var hasSetupFrontmostTracking = false
    private var activeFolderWatcherSignature: String?

    private static let pauseTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    nonisolated static func pauseDeadline(now: Date, minutes: Int = 0, hours: Int = 0, days: Int = 0) -> Date {
        let seconds = (minutes * 60) + (hours * 3600) + (days * 24 * 3600)
        return now.addingTimeInterval(TimeInterval(seconds))
    }

    init() {
        wireCoordinators()
        setupClipboardWatcher()
        setupFolderWatcher()
        setupOverlayActions()
        setupDropZoneActions()
        setupFrontmostAppTracking()
        notificationService.requestAuthorization()
        hotkeyCoordinator.onCopyOptimized = { [weak self] in self?.copyLastOptimized() }
        hotkeyCoordinator.onCopyOriginal = { [weak self] in self?.copyLastOriginal() }
        hotkeyCoordinator.register(viewModelPtr: Unmanaged.passUnretained(self).toOpaque())
        Task { @MainActor in
            self.startServices()
        }
    }

    deinit {
        MainActor.assumeIsolated {
            shutdown()
        }
    }

    // MARK: - Coordinator Wiring

    private func wireCoordinators() {
        processingCoordinator.settings = settings
        processingCoordinator.clipboardWatcher = clipboardWatcher
        processingCoordinator.overlayService = overlayService
        processingCoordinator.folderWatcher = folderWatcher
        processingCoordinator.dropZoneService = dropZoneService
        processingCoordinator.ignoreCache = ignoreCache
        processingCoordinator.contextAwareService = contextAwareService
        processingCoordinator.currentFrontmostBundleID = { [weak self] in
            self?.currentFrontmostBundleID() ?? ""
        }
        processingCoordinator.matchesFocusBundle = { [weak self] bundleID, focusBundleIDs in
            self?.matchesFocusBundle(bundleID, focusBundleIDs: focusBundleIDs) ?? false
        }
        processingCoordinator.onEventRecorded = { [weak self] event in
            self?.recordEvent(event)
        }
        contextAwareService.loadMappings(from: settings)

        // StatsService and ClipboardHistoryService need ModelContext,
        // which is available after modelContainer is created.
        // They are wired lazily in startServices().
    }

    private func wireSwiftDataServices() {
        let container = PersistenceController.shared.container
        let context = ModelContext(container)
        let stats = StatsService(modelContext: context)
        let history = ClipboardHistoryService(modelContext: context)
        let hashService = DuplicateHashService(modelContext: context)
        processingCoordinator.statsService = stats
        processingCoordinator.clipboardHistoryService = history
        processingCoordinator.duplicateHashService = hashService
    }

    private func recordEvent(_ event: OptimizationEvent) {
        events.insert(event, at: 0)
        if events.count > 100 {
            events = Array(events.prefix(100))
        }
        totalSaved += event.result.savingsBytes
        totalOptimized += 1
        requestReviewIfAppropriate()
    }

    private func requestReviewIfAppropriate() {
        let key = "lastReviewRequestOptimizationCount"
        let lastRequestCount = UserDefaults.standard.integer(forKey: key)
        // Request after 3rd, 20th, and every 50th optimization thereafter
        let shouldRequest = (totalOptimized == 3 && lastRequestCount < 3)
            || (totalOptimized == 20 && lastRequestCount < 20)
            || (totalOptimized >= 50 && totalOptimized % 50 == 0 && lastRequestCount < totalOptimized)
        guard shouldRequest else { return }
        UserDefaults.standard.set(totalOptimized, forKey: key)
        // Delay to avoid interrupting the user mid-paste
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            SKStoreReviewController.requestReview()
        }
    }

    // MARK: - Public

    var pauseStatusText: String {
        guard let until = settings.pauseUntil, settings.isPausedNow else { return "Active" }
        return "Paused until \(Self.pauseTimeFormatter.string(from: until))"
    }

    func startServices() {
        guard !hasStartedServices else { return }
        guard NSApp != nil else {
            DispatchQueue.main.async { [weak self] in
                self?.startServices()
            }
            return
        }
        hasStartedServices = true
        wireSwiftDataServices()
        presentOnboardingIfNeeded()
        if settings.dropZoneVisibleOnLaunch {
            dropZoneService.show()
        }
        refreshPauseState()
        Task { await tipStore.loadProducts() }
    }

    func stopServices() {
        clipboardWatcher.stop()
        stopFolderWatcher()
        hasStartedServices = false
    }

    func shutdown() {
        if let observer = onboardingCloseObserver {
            NotificationCenter.default.removeObserver(observer)
            onboardingCloseObserver = nil
        }
        if let observer = frontmostAppObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            frontmostAppObserver = nil
        }
        hotkeyCoordinator.unregister()
        hasSetupFrontmostTracking = false
        hasSetupClipboardWatcher = false
        hasSetupFolderWatcher = false
        hasSetupOverlayActions = false
        hasSetupDropZoneActions = false
        hasStartedServices = false
        clipboardWatcher.shutdown()
        folderWatcher.shutdown()
        activeFolderWatcherSignature = nil
        overlayService.shutdown()
        dropZoneService.shutdown()
    }

    func clearHistory() {
        events.removeAll()
        totalSaved = 0
        totalOptimized = 0
        log.app("Event history cleared")
    }

    func restoreOriginalFromHistory(_ entry: ClipboardHistoryEntry) {
        processingCoordinator.clipboardHistoryService?.restoreOriginal(entry: entry)
        if let path = entry.originalFileURL, let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            clipboardWatcher.updateHashTracking(data: data)
        }
    }

    func restoreOptimizedFromHistory(_ entry: ClipboardHistoryEntry) {
        processingCoordinator.clipboardHistoryService?.restoreOptimized(entry: entry)
        if let path = entry.optimizedFileURL, let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            clipboardWatcher.updateHashTracking(data: data)
        }
    }

    func clearAllHistory() {
        processingCoordinator.clipboardHistoryService?.clearAll()
    }

    func clearLastError() {
        processingCoordinator.clearLastError()
    }

    func copyLastOptimized() {
        guard let data = processingCoordinator.lastOptimizedData else {
            log.app("No optimized image available")
            return
        }
        clipboardWatcher.writeToPasteboard(data: data, format: processingCoordinator.lastOptimizedFormat)
        log.app("Copied last optimized image to clipboard (Option+1)")
    }

    func copyLastOriginal() {
        undoLastOptimization()
    }

    func undoLastOptimization() {
        guard let data = processingCoordinator.lastOriginalData else {
            log.app("No original image available for undo")
            return
        }
        clipboardWatcher.writeToPasteboard(data: data, format: processingCoordinator.lastOriginalFormat)
        log.app("Undo restored original image payload")
        overlayService.dismiss()
    }

    func optimizeManually(data: Data) {
        Task {
            await processingCoordinator.processImageData(
                data,
                source: .clipboard,
                fileName: nil,
                outputFormatOverride: nil,
                targetDimensions: nil,
                sourceBundleID: currentFrontmostBundleID()
            )
        }
    }

    func refreshPauseState() {
        if !settings.isPausedNow {
            settings.pauseUntil = nil
        }
        reconcileWatcherState()
    }

    func reconcileWatcherState() {
        if settings.isPausedNow {
            clipboardWatcher.stop()
            if settings.pauseFolderWatcher {
                stopFolderWatcher()
            } else if settings.folderWatchEnabled {
                startFolderWatcher()
            } else {
                stopFolderWatcher()
            }
        } else {
            if settings.clipboardWatchEnabled {
                clipboardWatcher.start()
            } else {
                clipboardWatcher.stop()
            }
            if settings.folderWatchEnabled {
                startFolderWatcher()
            } else {
                stopFolderWatcher()
            }
        }
    }

    func pauseFor(minutes: Int, now: Date = Date()) {
        settings.pauseUntil = Self.pauseDeadline(now: now, minutes: minutes)
        refreshPauseState()
    }

    func pauseFor(hours: Int, now: Date = Date()) {
        settings.pauseUntil = Self.pauseDeadline(now: now, hours: hours)
        refreshPauseState()
    }

    func pauseFor(days: Int, now: Date = Date()) {
        settings.pauseUntil = Self.pauseDeadline(now: now, days: days)
        refreshPauseState()
    }

    func resumeFromPause() {
        settings.pauseUntil = nil
        refreshPauseState()
    }

    @discardableResult
    func addWatchFolders() -> Bool {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.message = "Pick folders for ClipSlim to watch like an over-caffeinated hawk."
        panel.prompt = "Add Folders"

        if panel.runModal() == .OK {
            var folders = settings.watchedFolders
            let initialCount = folders.count
            for url in panel.urls {
                do {
                    let watched = try FolderBookmarkManager.makeWatchedFolder(from: url)
                    if !folders.contains(where: { $0.displayName == watched.displayName }) {
                        folders.append(watched)
                    }
                } catch {
                    log.folder("Failed creating bookmark for \(url.path): \(error.localizedDescription)", type: .error)
                }
            }
            settings.watchedFolders = folders
            if settings.folderWatchEnabled {
                startFolderWatcher()
            }
            return folders.count > initialCount
        }

        return false
    }

    func setFolderWatchEnabled(_ enabled: Bool) {
        if enabled {
            if settings.watchedFolders.isEmpty {
                settings.folderWatchEnabled = true
                let added = addWatchFolders()
                if !added && settings.watchedFolders.isEmpty {
                    settings.folderWatchEnabled = false
                }
            } else {
                settings.folderWatchEnabled = true
            }
        } else {
            settings.folderWatchEnabled = false
        }
        reconcileWatcherState()
    }

    func removeWatchFolder(_ folder: WatchedFolder) {
        settings.watchedFolders.removeAll { $0.id == folder.id }
        if settings.folderWatchEnabled && settings.watchedFolders.isEmpty {
            settings.folderWatchEnabled = false
        }
        reconcileWatcherState()
    }

    func completeOnboarding(
        preferredFormat: ImageFormat,
        optimizationIntensity: OptimizationIntensity,
        folders: [WatchedFolder],
        saveDestinationMode: SaveDestinationMode,
        customSaveFolderPath: String
    ) {
        settings.preferredOutputFormat = preferredFormat
        settings.applyOptimizationIntensity(optimizationIntensity)
        settings.watchedFolders = folders
        settings.saveDestinationMode = saveDestinationMode
        settings.saveFolderPath = customSaveFolderPath.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.clipboardWatchEnabled = true
        settings.pauseUntil = nil
        if !folders.isEmpty {
            settings.folderWatchEnabled = true
        } else {
            settings.folderWatchEnabled = false
        }
        settings.markOnboardingCompleted()
        refreshPauseState()
    }

    func runOnboardingAgain() {
        settings.onboardingCompleted = false
        presentOnboardingIfNeeded(force: true)
    }

    func ignoreCurrentImage() {
        guard let data = processingCoordinator.lastOriginalData else { return }
        ignoreCache.add(ClipboardWatcher.hash(data))
        overlayService.dismiss()
    }

    func ignoreCurrentApp() {
        let bundleID = processingCoordinator.lastSourceAppBundleID
        guard !bundleID.isEmpty else { return }
        var excluded = settings.excludedBundleIDs
        if !excluded.contains(bundleID) {
            excluded.append(bundleID)
            settings.excludedBundleIDs = excluded
        }
        overlayService.dismiss()
    }

    func removeImageFromClipboard() {
        _ = clipboardWatcher.removeImageContentSafely()
        overlayService.dismiss()
    }

    func saveLastPairAs() {
        guard let optimized = processingCoordinator.lastOptimizedData else { return }
        SaveCoordinator.shared.saveLastPairAs(optimizedData: optimized, format: processingCoordinator.lastOptimizedFormat)
    }

    func applyOneOffFormatOverride(_ format: ImageFormat) {
        guard let data = processingCoordinator.lastOriginalData else { return }
        Task {
            await processingCoordinator.processImageData(
                data,
                source: .clipboard,
                fileName: nil,
                outputFormatOverride: format,
                targetDimensions: nil,
                sourceBundleID: currentFrontmostBundleID()
            )
        }
    }

    func applyOneOffResizeOverride(width: Int, height: Int) {
        guard let data = processingCoordinator.lastOriginalData else { return }
        let clampedWidth = min(max(width, 16), 8192)
        let clampedHeight = min(max(height, 16), 8192)
        Task {
            await processingCoordinator.processImageData(
                data,
                source: .clipboard,
                fileName: nil,
                outputFormatOverride: nil,
                targetDimensions: (clampedWidth, clampedHeight),
                sourceBundleID: currentFrontmostBundleID()
            )
        }
    }

    func applyOneOffCrop(shape: CropShape, size: Int) {
        guard let data = processingCoordinator.lastOriginalData else { return }
        let clampedSize = min(max(size, 1), 8192)
        Task {
            do {
                let croppedData: Data
                let cropSuffix: String
                switch shape {
                case .square:
                    croppedData = try ImageOptimizer.shared.cropToSquare(data: data, side: clampedSize)
                    cropSuffix = "squared"
                case .circle:
                    croppedData = try ImageOptimizer.shared.cropToCircle(data: data, radius: clampedSize / 2)
                    cropSuffix = "circle"
                }
                clipboardWatcher.writeToPasteboard(data: croppedData, format: .png)
                Task {
                    await SaveCoordinator.shared.saveToDisk(
                        originalData: data,
                        optimizedData: croppedData,
                        format: .png,
                        fileName: nil,
                        sourceURL: nil,
                        settings: settings,
                        cropSuffix: cropSuffix
                    )
                }
                log.app("Crop applied: \(shape.rawValue) size \(clampedSize)")
            } catch {
                log.error("Crop failed: \(error.localizedDescription)", category: "optimizer")
            }
        }
    }

    func openSettingsWindow() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    func toggleDropZone() {
        dropZoneService.toggle()
    }

    // MARK: - Private Setup

    private func setupClipboardWatcher() {
        guard !hasSetupClipboardWatcher else { return }
        hasSetupClipboardWatcher = true
        clipboardWatcher.onImageDetected = { [weak self] data in
            guard let self else { return }
            let sourceBundleID = self.currentFrontmostBundleID()
            Task { @MainActor in
                await self.processingCoordinator.processImageData(
                    data,
                    source: .clipboard,
                    fileName: nil,
                    outputFormatOverride: nil,
                    targetDimensions: nil,
                    sourceBundleID: sourceBundleID
                )
            }
        }
    }

    private func setupFolderWatcher() {
        guard !hasSetupFolderWatcher else { return }
        hasSetupFolderWatcher = true
        folderWatcher.onFileDetected = { [weak self] url in
            guard let self else { return }
            Task { @MainActor in
                await self.processingCoordinator.processFileURL(url)
            }
        }

        folderWatcher.onBookmarkNeedsRefresh = { [weak self] staleFolder in
            guard let self else { return }
            self.log.folder("Bookmark stale for \(staleFolder.displayName); keeping until user refreshes")
        }
    }

    private func setupOverlayActions() {
        guard !hasSetupOverlayActions else { return }
        hasSetupOverlayActions = true
        overlayService.onUndo = { [weak self] in self?.undoLastOptimization() }
        overlayService.onSaveAs = { [weak self] in self?.saveLastPairAs() }
        overlayService.onRemoveClipboardImage = { [weak self] in self?.removeImageFromClipboard() }
        overlayService.onApplyFormatOverride = { [weak self] format in self?.applyOneOffFormatOverride(format) }
        overlayService.onApplyResizeOverride = { [weak self] width, height in
            self?.applyOneOffResizeOverride(width: width, height: height)
        }
        overlayService.onApplyCrop = { [weak self] shape, size in
            self?.applyOneOffCrop(shape: shape, size: size)
        }
        overlayService.onOpenSettings = { [weak self] in self?.openSettingsWindow() }
        overlayService.onIgnoreImage = { [weak self] in self?.ignoreCurrentImage() }
        overlayService.onIgnoreApp = { [weak self] in self?.ignoreCurrentApp() }
        overlayService.onAcceptSuggestion = { [weak self] in self?.acceptContextSuggestion() }
        overlayService.onDismissSuggestion = { [weak self] in self?.dismissContextSuggestion() }
        overlayService.onReuseDuplicate = { [weak self] in
            // F6: Reuse previously optimized data from the overlay item
            if let item = self?.overlayService.currentItem, let dupData = item.duplicateOptimizedData {
                self?.clipboardWatcher.writeToPasteboard(data: dupData, format: item.result.format)
            }
            self?.overlayService.dismiss()
        }
    }

    private func acceptContextSuggestion() {
        let bundleID = processingCoordinator.lastSourceAppBundleID
        guard !bundleID.isEmpty else { return }
        contextAwareService.recordAccept(for: bundleID, settings: settings)
        overlayService.dismiss()
        // Re-process with the suggested preset
        if let data = processingCoordinator.lastOriginalData {
            Task {
                await processingCoordinator.processImageData(
                    data, source: .clipboard, fileName: nil,
                    outputFormatOverride: nil, targetDimensions: nil,
                    sourceBundleID: bundleID
                )
            }
        }
    }

    private func dismissContextSuggestion() {
        let bundleID = processingCoordinator.lastSourceAppBundleID
        guard !bundleID.isEmpty else { return }
        contextAwareService.recordDismiss(for: bundleID, settings: settings)
        // Don't dismiss overlay — user keeps the current optimization
    }

    private func setupDropZoneActions() {
        guard !hasSetupDropZoneActions else { return }
        hasSetupDropZoneActions = true
        dropZoneService.onFilesDropped = { [weak self] urls in
            guard let self else { return }
            Task { @MainActor in
                await self.processingCoordinator.processDroppedFiles(urls)
            }
        }
        // F7: Single-item drop → quick action overlay
        dropZoneService.onSingleFileDropped = { [weak self] url in
            guard let self else { return }
            self.showQuickActionOverlay(for: url)
        }
    }

    private var quickActionWindow: NSWindow?

    private func showQuickActionOverlay(for url: URL) {
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
        let view = QuickActionOverlayView(
            fileName: url.lastPathComponent,
            fileSize: fileSize,
            onCompress: { [weak self] in
                self?.quickActionWindow?.close()
                Task { @MainActor [weak self] in
                    await self?.processingCoordinator.processDroppedFiles([url])
                }
            },
            onCopy: { [weak self] in
                self?.quickActionWindow?.close()
                if let data = try? Data(contentsOf: url) {
                    let format = ImageFormat(rawValue: url.pathExtension.uppercased()) ?? .png
                    self?.clipboardWatcher.writeToPasteboard(data: data, format: format)
                }
            },
            onSave: { [weak self] in
                self?.quickActionWindow?.close()
                Task { @MainActor [weak self] in
                    await self?.processingCoordinator.processDroppedFiles([url])
                }
            },
            onDismiss: { [weak self] in
                self?.quickActionWindow?.close()
            }
        )

        let hosting = NSHostingView(rootView: view)
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 320),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.isFloatingPanel = true
        window.level = .floating
        window.hasShadow = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.contentView = hosting

        // Position near mouse
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouseLocation) } ?? NSScreen.main
        if let screen {
            let x = min(mouseLocation.x, screen.visibleFrame.maxX - 300)
            let y = min(mouseLocation.y, screen.visibleFrame.maxY - 340)
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        window.orderFrontRegardless()
        quickActionWindow = window
    }

    private func setupFrontmostAppTracking() {
        guard !hasSetupFrontmostTracking else { return }
        hasSetupFrontmostTracking = true
        updateFrontmostBundleID()
        frontmostAppObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateFrontmostBundleID()
                self?.reconcileWatcherState()
            }
        }
    }

    private func updateFrontmostBundleID() {
        lastKnownFrontmostBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
    }

    func currentFrontmostBundleID() -> String {
        let current = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
        if !current.isEmpty {
            lastKnownFrontmostBundleID = current
            return current
        }
        return lastKnownFrontmostBundleID
    }

    private func presentOnboardingIfNeeded(force: Bool = false) {
        let shouldShow = force || settings.shouldPresentOnboarding
        guard shouldShow else { return }
        guard onboardingWindow == nil else { return }
        settings.markOnboardingPresented()

        let view = OnboardingFlowView(onComplete: { [weak self] in
            self?.onboardingWindow?.close()
            self?.onboardingWindow = nil
        })
        .environment(self)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.contentView = NSHostingView(rootView: view)
        window.title = "ClipSlim Onboarding"
        window.isReleasedWhenClosed = false
        window.center()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        onboardingWindow = window

        onboardingCloseObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.onboardingWindow = nil
                if let observer = self.onboardingCloseObserver {
                    NotificationCenter.default.removeObserver(observer)
                    self.onboardingCloseObserver = nil
                }
            }
        }
    }

    private func startFolderWatcher() {
        let folders = settings.watchedFolders
        guard !folders.isEmpty else {
            log.folder("No watched folders configured")
            activeFolderWatcherSignature = nil
            return
        }

        let signature = Self.folderWatcherSignature(for: folders)
        if folderWatcher.isWatching, activeFolderWatcherSignature == signature {
            return
        }

        folderWatcher.start(folders: folders)
        activeFolderWatcherSignature = folderWatcher.isWatching ? signature : nil
    }

    private func stopFolderWatcher() {
        folderWatcher.stop()
        activeFolderWatcherSignature = nil
    }

    nonisolated static func folderWatcherSignature(for folders: [WatchedFolder]) -> String {
        folders
            .sorted { $0.id.uuidString < $1.id.uuidString }
            .map { "\($0.id.uuidString)|\($0.displayName)|\($0.bookmarkData.base64EncodedString())" }
            .joined(separator: ";")
    }

    private func matchesFocusBundle(_ bundleID: String, focusBundleIDs: [String]) -> Bool {
        guard !bundleID.isEmpty else { return false }
        for focused in focusBundleIDs {
            if focused == "*" { return true }
            if bundleID == focused { return true }
            if bundleID.hasPrefix(focused) { return true }
        }
        return false
    }
}
