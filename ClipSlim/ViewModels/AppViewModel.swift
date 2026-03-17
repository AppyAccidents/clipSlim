import Foundation
import AppKit
import Carbon.HIToolbox
import ImageIO
import SwiftUI

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

    private(set) var events: [OptimizationEvent] = []
    private(set) var totalSaved: Int = 0
    private(set) var totalOptimized: Int = 0
    private(set) var isProcessing = false
    private(set) var lastError: String?

    private(set) var lastOriginalData: Data?
    private(set) var lastOptimizedData: Data?
    private(set) var lastOptimizedFormat: ImageFormat = .jpeg
    private(set) var lastOriginalFormat: ImageFormat = .png
    private(set) var lastSourceAppBundleID: String = ""

    private let optimizer = ImageOptimizer.shared
    private let pdfOptimizer = PDFOptimizer.shared
    private let notificationService = NotificationService.shared
    private let log = Logger.shared

    private var hotKeyRef1: EventHotKeyRef?
    private var hotKeyRef2: EventHotKeyRef?

    private var optimizationCache: [String: (Data, OptimizationResult)] = [:]
    private var optimizationCacheOrder: [String] = []
    private let maxOptimizationCacheEntries = 10

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
    private var hasRegisteredHotkeys = false
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
        setupClipboardWatcher()
        setupFolderWatcher()
        setupOverlayActions()
        setupDropZoneActions()
        setupFrontmostAppTracking()
        notificationService.requestAuthorization()
        registerGlobalHotkeys()
        Task { @MainActor in
            self.startServices()
        }
    }

    deinit {
        MainActor.assumeIsolated {
            shutdown()
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
        if let hotKeyRef1 {
            UnregisterEventHotKey(hotKeyRef1)
            self.hotKeyRef1 = nil
        }
        if let hotKeyRef2 {
            UnregisterEventHotKey(hotKeyRef2)
            self.hotKeyRef2 = nil
        }
        hasRegisteredHotkeys = false
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

    func clearLastError() {
        lastError = nil
    }

    func copyLastOptimized() {
        guard let data = lastOptimizedData else {
            log.app("No optimized image available")
            return
        }
        clipboardWatcher.writeToPasteboard(data: data, format: lastOptimizedFormat)
        log.app("Copied last optimized image to clipboard (Option+1)")
    }

    func copyLastOriginal() {
        undoLastOptimization()
    }

    func undoLastOptimization() {
        guard let data = lastOriginalData else {
            log.app("No original image available for undo")
            return
        }
        clipboardWatcher.writeToPasteboard(data: data, format: lastOriginalFormat)
        log.app("Undo restored original image payload")
        overlayService.dismiss()
    }

    func optimizeManually(data: Data) {
        Task {
            await processImageData(
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
        guard let data = lastOriginalData else { return }
        ignoreCache.add(ClipboardWatcher.hash(data))
        overlayService.dismiss()
    }

    func ignoreCurrentApp() {
        guard !lastSourceAppBundleID.isEmpty else { return }
        var excluded = settings.excludedBundleIDs
        if !excluded.contains(lastSourceAppBundleID) {
            excluded.append(lastSourceAppBundleID)
            settings.excludedBundleIDs = excluded
        }
        overlayService.dismiss()
    }

    func removeImageFromClipboard() {
        _ = clipboardWatcher.removeImageContentSafely()
        overlayService.dismiss()
    }

    func saveLastPairAs() {
        guard let optimized = lastOptimizedData else { return }

        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose where to save the optimized image"
        panel.prompt = "Save"

        guard panel.runModal() == .OK, let base = panel.url else { return }

        let safeBase = safeFilenameBase(defaultName: "clipslim")
        let optimizedURL = base.appendingPathComponent("\(safeBase)_optimized.\(lastOptimizedFormat.fileExtension)")

        Task {
            do {
                try await Task.detached(priority: .utility) {
                    try optimized.write(to: optimizedURL, options: .atomic)
                }.value
                log.app("Saved optimized image via Save As")
            } catch {
                log.error("Save As failed: \(error.localizedDescription)")
            }
        }
    }

    func applyOneOffFormatOverride(_ format: ImageFormat) {
        guard let data = lastOriginalData else { return }
        Task {
            await processImageData(
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
        guard let data = lastOriginalData else { return }
        let clampedWidth = min(max(width, 16), 8192)
        let clampedHeight = min(max(height, 16), 8192)
        Task {
            await processImageData(
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
        guard let data = lastOriginalData else { return }
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
                lastOptimizedData = croppedData
                lastOptimizedFormat = .png
                Task {
                    await saveToDisk(
                        originalData: data,
                        optimizedData: croppedData,
                        format: .png,
                        fileName: nil,
                        sourceURL: nil,
                        cropSuffix: cropSuffix
                    )
                }
                log.app("Crop applied: \(shape.rawValue) size \(clampedSize)")
            } catch {
                lastError = error.localizedDescription
                log.error("Crop failed: \(error.localizedDescription)", category: "optimizer")
            }
        }
    }

    func openSettingsWindow() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    // MARK: - Private Setup

    private func setupClipboardWatcher() {
        guard !hasSetupClipboardWatcher else { return }
        hasSetupClipboardWatcher = true
        clipboardWatcher.onImageDetected = { [weak self] data in
            guard let self else { return }
            let sourceBundleID = self.currentFrontmostBundleID()
            Task { @MainActor in
                await self.processImageData(
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
                await self.processFileURL(url)
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
    }

    private func setupDropZoneActions() {
        guard !hasSetupDropZoneActions else { return }
        hasSetupDropZoneActions = true
        dropZoneService.onFilesDropped = { [weak self] urls in
            guard let self else { return }
            Task { @MainActor in
                await self.processDroppedFiles(urls)
            }
        }
    }

    func toggleDropZone() {
        dropZoneService.toggle()
    }

    private func processDroppedFiles(_ urls: [URL]) async {
        guard !isProcessing else { return }
        isProcessing = true
        dropZoneService.isProcessing = true
        defer {
            dropZoneService.isProcessing = false
            isProcessing = false
        }

        for url in urls {
            let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
            let itemID = dropZoneService.addPendingItem(fileName: url.lastPathComponent, originalSize: fileSize)
            dropZoneService.updateItem(id: itemID, state: .processing)

            let fileType = OptimizableFileType.from(url: url)

            do {
                switch fileType {
                case .pdf:
                    guard settings.pdfCompressionEnabled else {
                        dropZoneService.updateItem(id: itemID, state: .failed("PDF compression disabled"))
                        continue
                    }
                    let data = try Data(contentsOf: url)
                    let config = PDFOptimizer.PDFOptimizationConfig(from: settings)
                    let (optimizedData, pdfResult) = try await OptimizationDispatch.run {
                        try PDFOptimizer.shared.optimize(data: data, config: config)
                    }

                    guard pdfResult.optimizedSize < pdfResult.originalSize else {
                        dropZoneService.updateItem(id: itemID, state: .failed("PDF is already optimized"))
                        continue
                    }

                    // Save optimized PDF next to original
                    let outputURL = url.deletingLastPathComponent()
                        .appendingPathComponent(url.deletingPathExtension().lastPathComponent + "-optimized.pdf")
                    try optimizedData.write(to: outputURL, options: .atomic)

                    let imageResult = OptimizationResult(
                        originalSize: pdfResult.originalSize,
                        optimizedSize: pdfResult.optimizedSize,
                        format: .jpeg,
                        duration: pdfResult.duration,
                        originalDimensions: (0, 0),
                        optimizedDimensions: (0, 0)
                    )

                    let event = OptimizationEvent(
                        timestamp: Date(),
                        source: .dropZone,
                        result: imageResult,
                        fileName: url.lastPathComponent
                    )
                    events.insert(event, at: 0)
                    if events.count > 100 { events = Array(events.prefix(100)) }
                    totalSaved += pdfResult.savingsBytes
                    totalOptimized += 1

                    dropZoneService.updateItem(id: itemID, state: .completed(
                        savedBytes: pdfResult.savingsBytes,
                        savingsPercent: pdfResult.savingsPercentage
                    ))

                case .image, nil:
                    let data = try Data(contentsOf: url)
                    let config = ImageOptimizer.OptimizationConfig(from: settings)
                    let (optimizedData, result) = try await OptimizationDispatch.run {
                        try await ImageOptimizer.shared.optimize(data: data, config: config)
                    }

                    guard result.optimizedSize < result.originalSize else {
                        dropZoneService.updateItem(id: itemID, state: .failed("No size reduction"))
                        continue
                    }

                    let nameWithoutExt = url.deletingPathExtension().lastPathComponent
                    let outputURL = url.deletingLastPathComponent()
                        .appendingPathComponent("\(nameWithoutExt)-optimized.\(result.format.fileExtension)")
                    try optimizedData.write(to: outputURL, options: .atomic)

                    let event = OptimizationEvent(
                        timestamp: Date(),
                        source: .dropZone,
                        result: result,
                        fileName: url.lastPathComponent
                    )
                    events.insert(event, at: 0)
                    if events.count > 100 { events = Array(events.prefix(100)) }
                    totalSaved += result.savingsBytes
                    totalOptimized += 1

                    dropZoneService.updateItem(id: itemID, state: .completed(
                        savedBytes: result.savingsBytes,
                        savingsPercent: result.savingsPercentage
                    ))
                }

                if settings.notificationsEnabled {
                    notificationService.sendOptimizationNotification(
                        result: events.first!.result,
                        source: .dropZone
                    )
                }
            } catch {
                dropZoneService.updateItem(id: itemID, state: .failed(error.localizedDescription))
                log.error("Drop zone optimization failed for \(url.lastPathComponent): \(error.localizedDescription)", category: "dropzone")
            }
        }
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

    private func currentFrontmostBundleID() -> String {
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

    // MARK: - Global Hotkeys

    private func registerGlobalHotkeys() {
        guard !hasRegisteredHotkeys else { return }
        hasRegisteredHotkeys = true
        let viewModelPtr = Unmanaged.passUnretained(self).toOpaque()

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData -> OSStatus in
            guard let event, let userData else { return OSStatus(eventNotHandledErr) }
            var hotKeyID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)

            let vm = Unmanaged<AppViewModel>.fromOpaque(userData).takeUnretainedValue()

            DispatchQueue.main.async {
                switch hotKeyID.id {
                case 1:
                    vm.copyLastOptimized()
                case 2:
                    vm.copyLastOriginal()
                default:
                    break
                }
            }
            return noErr
        }, 1, &eventType, viewModelPtr, nil)

        let hotKeyID1 = EventHotKeyID(signature: OSType(0x434C5031), id: 1)
        RegisterEventHotKey(UInt32(kVK_ANSI_1), UInt32(optionKey), hotKeyID1, GetApplicationEventTarget(), 0, &hotKeyRef1)

        let hotKeyID2 = EventHotKeyID(signature: OSType(0x434C5032), id: 2)
        RegisterEventHotKey(UInt32(kVK_ANSI_2), UInt32(optionKey), hotKeyID2, GetApplicationEventTarget(), 0, &hotKeyRef2)

        log.app("Global hotkeys registered: Option+1 (optimized), Option+2 (original)")
    }

    // MARK: - Save to Disk

    private func saveToDisk(
        originalData: Data,
        optimizedData: Data,
        format: ImageFormat,
        fileName: String?,
        sourceURL: URL?,
        cropSuffix: String? = nil
    ) async {
        guard settings.saveToDisk else { return }

        let basePath: String
        switch settings.saveDestinationMode {
        case .sameFolder:
            if let sourceURL {
                basePath = sourceURL.deletingLastPathComponent().path
            } else if !settings.saveFolderPath.isEmpty {
                basePath = settings.saveFolderPath
            } else {
                log.app("Skip save: no custom fallback folder for clipboard image in same-folder mode")
                return
            }
        case .customFolder:
            guard !settings.saveFolderPath.isEmpty else {
                log.app("Skip save: custom save folder is not configured")
                return
            }
            basePath = settings.saveFolderPath
        }

        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let baseName = fileName ?? "clipboard-\(timestamp)"
        let nameWithoutExt = sanitizeFilename((baseName as NSString).deletingPathExtension)
        let origExt = (baseName as NSString).pathExtension.isEmpty ? "png" : (baseName as NSString).pathExtension

        let optimizedSuffix: String
        if let suffix = cropSuffix {
            optimizedSuffix = "_optimized_\(suffix)"
        } else {
            optimizedSuffix = "_optimized"
        }

        let originalsPath = (basePath as NSString).appendingPathComponent("Originals")
        let optimizedPathBase = (basePath as NSString).appendingPathComponent("Optimized")

        let originalPath = (originalsPath as NSString).appendingPathComponent("\(nameWithoutExt).\(origExt)")
        let optimizedPath = (optimizedPathBase as NSString).appendingPathComponent("\(nameWithoutExt)\(optimizedSuffix).\(format.fileExtension)")

        do {
            try await Task.detached(priority: .utility) {
                try FileManager.default.createDirectory(atPath: originalsPath, withIntermediateDirectories: true, attributes: nil)
                try FileManager.default.createDirectory(atPath: optimizedPathBase, withIntermediateDirectories: true, attributes: nil)
                try originalData.write(to: URL(fileURLWithPath: originalPath), options: .atomic)
                try optimizedData.write(to: URL(fileURLWithPath: optimizedPath), options: .atomic)
            }.value
            log.app("Saved original/optimized pair to \(basePath)")
        } catch {
            log.error("Failed to save to disk: \(error.localizedDescription)")
        }
    }

    // MARK: - Processing

    private func processImageData(
        _ data: Data,
        source: OptimizationEvent.Source,
        fileName: String?,
        outputFormatOverride: ImageFormat?,
        targetDimensions: (width: Int, height: Int)?,
        sourceBundleID: String?
    ) async {
        // Check if data is actually a PDF and route accordingly
        if let fileType = OptimizableFileType.from(data: data), fileType.isPDF {
            await processClipboardPDF(data, sourceBundleID: sourceBundleID)
            return
        }

        if settings.isPausedNow {
            return
        }

        if isProcessing {
            log.app("Already processing, skipping")
            return
        }

        isProcessing = true
        lastError = nil

        defer { isProcessing = false }

        do {
            let sourceBundleID = sourceBundleID ?? currentFrontmostBundleID()
            lastSourceAppBundleID = sourceBundleID
            let excludedBundleIDs = Set(settings.excludedBundleIDs)
            let focusedBundleIDs = settings.focusBundleIDs

            if excludedBundleIDs.contains(sourceBundleID) {
                return
            }

            let isFocusMode = source == .clipboard && settings.focusModeEnabled && matchesFocusBundle(sourceBundleID, focusBundleIDs: focusedBundleIDs)

            let sourceHash = ClipboardWatcher.hash(data)
            if source == .clipboard && ignoreCache.contains(sourceHash) {
                log.clipboard("Skipped image due to ignore cache")
                return
            }

            let info = await Task.detached(priority: .utility) {
                ImageOptimizer.shared.inspect(data: data) ?? .init(dimensions: (0, 0), hasAlpha: false)
            }.value

            let effectiveFormat = outputFormatOverride
            let effectivePreset = settings.selectedPreset
            let quality: Double
            if settings.overridePresetQuality {
                quality = settings.globalQualityValue
            } else {
                quality = effectivePreset == .custom ? settings.customQuality : effectivePreset.quality
            }
            let maxDimension = effectivePreset == .custom ? settings.customMaxDimension : effectivePreset.maxDimension
            let stripMetadata = effectivePreset == .custom ? settings.customStripMetadata : effectivePreset.stripMetadata
            let allowTransparencyLoss = effectivePreset == .custom ? settings.customAllowTransparencyLoss : effectivePreset.allowTransparencyLoss

            let config = ImageOptimizer.OptimizationConfig(
                quality: quality,
                maxDimension: maxDimension,
                stripMetadata: stripMetadata,
                allowTransparencyLoss: allowTransparencyLoss,
                preferredFormat: settings.preferredOutputFormat,
                preserveAlphaByForcingPNG: settings.preserveAlphaByForcingPNG,
                outputFormatOverride: effectiveFormat,
                targetDimensions: targetDimensions
            )
            let cacheKey = cacheKeyFor(hash: sourceHash, config: config)

            let optimizedData: Data
            let result: OptimizationResult

            if let cached = optimizationCache[cacheKey] {
                optimizedData = cached.0
                result = cached.1
            } else {
                let optimizedTuple = try await OptimizationDispatch.run {
                    try await ImageOptimizer.shared.optimize(data: data, config: config)
                }
                optimizedData = optimizedTuple.data
                result = optimizedTuple.result
                cacheOptimization(cacheKey: cacheKey, data: optimizedData, result: result)
            }

            var bestData = optimizedData
            var bestResult = result
            let isForcedTransformation = outputFormatOverride != nil || targetDimensions != nil

            if !isMeaningfulSavings(result),
               !isForcedTransformation {
                let preferredCandidate = config.outputFormatOverride ?? settings.preferredOutputFormat
                let alternateFormat: ImageFormat = preferredCandidate == .jpeg ? .png : .jpeg
                let canTryAlternate = alternateFormat == .png || !info.hasAlpha || allowTransparencyLoss
                if canTryAlternate {
                    let alternateConfig = ImageOptimizer.OptimizationConfig(
                        quality: quality,
                        maxDimension: maxDimension,
                        stripMetadata: stripMetadata,
                        allowTransparencyLoss: allowTransparencyLoss,
                        preferredFormat: settings.preferredOutputFormat,
                        preserveAlphaByForcingPNG: settings.preserveAlphaByForcingPNG,
                        outputFormatOverride: alternateFormat,
                        targetDimensions: targetDimensions
                    )
                    let alternateKey = cacheKeyFor(hash: sourceHash, config: alternateConfig)

                    let alternateData: Data
                    let alternateResult: OptimizationResult
                    if let cachedAlternate = optimizationCache[alternateKey] {
                        alternateData = cachedAlternate.0
                        alternateResult = cachedAlternate.1
                    } else {
                        let tuple = try await OptimizationDispatch.run {
                            try await ImageOptimizer.shared.optimize(data: data, config: alternateConfig)
                        }
                        alternateData = tuple.data
                        alternateResult = tuple.result
                        cacheOptimization(cacheKey: alternateKey, data: alternateData, result: alternateResult)
                    }

                    if alternateResult.optimizedSize < bestResult.optimizedSize {
                        bestData = alternateData
                        bestResult = alternateResult
                    }
                }
            }

            lastOriginalData = data
            lastOptimizedData = bestData
            lastOptimizedFormat = bestResult.format
            lastOriginalFormat = detectFormat(from: data)

            guard isForcedTransformation || isMeaningfulSavings(bestResult) else {
                log.app("Skipping: optimized output is not smaller (\(bestResult.formattedOriginalSize) -> \(bestResult.formattedOptimizedSize), \(String(format: "%.2f", bestResult.savingsPercentage))%)")
                return
            }

            if source == .clipboard {
                clipboardWatcher.writeToPasteboard(data: bestData, format: bestResult.format)
                if !isFocusMode {
                    overlayService.show(item: OverlayItem(
                        originalData: data,
                        optimizedData: bestData,
                        result: bestResult,
                        formatOverrideSelection: bestResult.format,
                        sourceAppBundleID: sourceBundleID
                    ))
                }
            }

            let event = OptimizationEvent(
                timestamp: Date(),
                source: source,
                result: bestResult,
                fileName: fileName
            )
            events.insert(event, at: 0)
            if events.count > 100 {
                events = Array(events.prefix(100))
            }

            totalSaved += bestResult.savingsBytes
            totalOptimized += 1

            if settings.notificationsEnabled {
                notificationService.sendOptimizationNotification(result: bestResult, source: source)
            }

            Task {
                await saveToDisk(
                    originalData: data,
                    optimizedData: bestData,
                    format: bestResult.format,
                    fileName: fileName,
                    sourceURL: nil
                )
            }

            log.app("Optimization complete: \(bestResult.formattedOriginalSize) -> \(bestResult.formattedOptimizedSize) (\(String(format: "%.1f", bestResult.savingsPercentage))%)")
        } catch {
            lastError = error.localizedDescription
            log.error("Optimization failed: \(error.localizedDescription)", category: "optimizer")
        }
    }

    private func processFileURL(_ url: URL) async {
        let fileType = OptimizableFileType.from(url: url)

        if case .pdf = fileType {
            await processPDFFileURL(url)
            return
        }

        do {
            let config = ImageOptimizer.OptimizationConfig(from: settings)
            let (data, optimizedData, result) = try await OptimizationDispatch.run {
                let data = try Data(contentsOf: url)
                let (optimizedData, result) = try await ImageOptimizer.shared.optimize(data: data, config: config)
                return (data, optimizedData, result)
            }

            guard isMeaningfulSavings(result) else {
                log.folder("Skipping \(url.lastPathComponent): no meaningful savings (\(String(format: "%.2f", result.savingsPercentage))%)")
                return
            }

            lastOriginalData = data
            lastOptimizedData = optimizedData
            lastOptimizedFormat = result.format
            lastOriginalFormat = detectFormat(from: data)

            let outputURL = folderWatcher.outputURL(for: url, format: result.format)
            try await Task.detached(priority: .utility) {
                try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                try optimizedData.write(to: outputURL, options: .atomic)
            }.value

            let event = OptimizationEvent(
                timestamp: Date(),
                source: .folder,
                result: result,
                fileName: url.lastPathComponent
            )

            events.insert(event, at: 0)
            if events.count > 100 {
                events = Array(events.prefix(100))
            }
            totalSaved += result.savingsBytes
            totalOptimized += 1

            if settings.notificationsEnabled {
                notificationService.sendOptimizationNotification(result: result, source: .folder)
            }

            Task {
                await saveToDisk(
                    originalData: data,
                    optimizedData: optimizedData,
                    format: result.format,
                    fileName: url.lastPathComponent,
                    sourceURL: url
                )
            }

            log.folder("Optimized \(url.lastPathComponent) -> \(outputURL.lastPathComponent)")
        } catch {
            log.error("Folder optimization failed for \(url.lastPathComponent): \(error.localizedDescription)", category: "folder")
        }
    }

    private func processPDFFileURL(_ url: URL) async {
        guard settings.pdfCompressionEnabled else {
            log.folder("PDF compression disabled, skipping \(url.lastPathComponent)")
            return
        }

        do {
            let config = PDFOptimizer.PDFOptimizationConfig(from: settings)
            let (optimizedData, pdfResult) = try await OptimizationDispatch.run {
                let data = try Data(contentsOf: url)
                return try PDFOptimizer.shared.optimize(data: data, config: config)
            }

            guard pdfResult.optimizedSize < pdfResult.originalSize else {
                log.folder("Skipping PDF \(url.lastPathComponent): already optimized")
                return
            }

            // Write to Optimized subfolder like images
            let parent = url.deletingLastPathComponent()
            let optimizedDir = parent.appendingPathComponent("Optimized", isDirectory: true)
            let outputURL = optimizedDir.appendingPathComponent(
                url.deletingPathExtension().lastPathComponent + "-optimized.pdf"
            )
            try await Task.detached(priority: .utility) {
                try FileManager.default.createDirectory(at: optimizedDir, withIntermediateDirectories: true, attributes: nil)
                try optimizedData.write(to: outputURL, options: .atomic)
            }.value

            let result = OptimizationResult(
                originalSize: pdfResult.originalSize,
                optimizedSize: pdfResult.optimizedSize,
                format: .jpeg,
                duration: pdfResult.duration,
                originalDimensions: (0, 0),
                optimizedDimensions: (0, 0)
            )

            let event = OptimizationEvent(
                timestamp: Date(),
                source: .folder,
                result: result,
                fileName: url.lastPathComponent
            )
            events.insert(event, at: 0)
            if events.count > 100 { events = Array(events.prefix(100)) }
            totalSaved += pdfResult.savingsBytes
            totalOptimized += 1

            if settings.notificationsEnabled {
                notificationService.sendOptimizationNotification(result: result, source: .folder)
            }

            log.folder("Optimized PDF \(url.lastPathComponent) -> \(outputURL.lastPathComponent) (\(pdfResult.pageCount) pages)")
        } catch {
            log.error("PDF folder optimization failed for \(url.lastPathComponent): \(error.localizedDescription)", category: "folder")
        }
    }

    // MARK: - PDF Processing

    private func processClipboardPDF(_ data: Data, sourceBundleID: String?) async {
        guard settings.pdfCompressionEnabled else {
            log.app("PDF compression disabled, skipping clipboard PDF")
            return
        }

        if settings.isPausedNow { return }
        if isProcessing {
            log.app("Already processing, skipping")
            return
        }

        isProcessing = true
        lastError = nil
        defer { isProcessing = false }

        do {
            let config = PDFOptimizer.PDFOptimizationConfig(from: settings)
            let (optimizedData, pdfResult) = try await OptimizationDispatch.run {
                try PDFOptimizer.shared.optimize(data: data, config: config)
            }

            guard pdfResult.optimizedSize < pdfResult.originalSize else {
                log.app("Skipping clipboard PDF: already optimized")
                return
            }

            lastOriginalData = data
            lastOptimizedData = optimizedData
            lastOptimizedFormat = .jpeg
            lastOriginalFormat = .png

            // Write optimized PDF back to clipboard
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setData(optimizedData, forType: NSPasteboard.PasteboardType("com.adobe.pdf"))
            clipboardWatcher.updateHashTracking(data: optimizedData)

            let result = OptimizationResult(
                originalSize: pdfResult.originalSize,
                optimizedSize: pdfResult.optimizedSize,
                format: .jpeg,
                duration: pdfResult.duration,
                originalDimensions: (0, 0),
                optimizedDimensions: (0, 0)
            )

            let bundleID = sourceBundleID ?? currentFrontmostBundleID()
            let isFocusMode = settings.focusModeEnabled && matchesFocusBundle(bundleID, focusBundleIDs: settings.focusBundleIDs)

            if !isFocusMode {
                overlayService.show(item: OverlayItem(
                    originalData: data,
                    optimizedData: optimizedData,
                    result: result,
                    formatOverrideSelection: .jpeg,
                    sourceAppBundleID: bundleID,
                    pdfPageCount: pdfResult.pageCount
                ))
            }

            let event = OptimizationEvent(
                timestamp: Date(),
                source: .clipboard,
                result: result,
                fileName: "clipboard.pdf"
            )
            events.insert(event, at: 0)
            if events.count > 100 { events = Array(events.prefix(100)) }
            totalSaved += pdfResult.savingsBytes
            totalOptimized += 1

            if settings.notificationsEnabled {
                notificationService.sendOptimizationNotification(result: result, source: .clipboard)
            }

            Task {
                await saveToDisk(
                    originalData: data,
                    optimizedData: optimizedData,
                    format: .jpeg,
                    fileName: "clipboard.pdf",
                    sourceURL: nil
                )
            }

            log.app("PDF optimization complete: \(pdfResult.formattedOriginalSize) -> \(pdfResult.formattedOptimizedSize) (\(pdfResult.pageCount) pages)")
        } catch {
            lastError = error.localizedDescription
            log.error("Clipboard PDF optimization failed: \(error.localizedDescription)", category: "optimizer")
        }
    }

    // MARK: - Helpers

    private func cacheKeyFor(hash: String, config: ImageOptimizer.OptimizationConfig) -> String {
        [
            hash,
            String(format: "%.3f", config.quality),
            "\(config.maxDimension)",
            config.stripMetadata ? "meta0" : "meta1",
            config.allowTransparencyLoss ? "alpha0" : "alpha1",
            config.preferredFormat.rawValue,
            config.outputFormatOverride?.rawValue ?? "none",
            config.targetDimensions.map { "\($0.width)x\($0.height)" } ?? "source"
        ].joined(separator: "|")
    }

    private func cacheOptimization(cacheKey: String, data: Data, result: OptimizationResult) {
        optimizationCache[cacheKey] = (data, result)
        optimizationCacheOrder.removeAll { $0 == cacheKey }
        optimizationCacheOrder.append(cacheKey)

        while optimizationCacheOrder.count > maxOptimizationCacheEntries {
            let oldest = optimizationCacheOrder.removeFirst()
            optimizationCache.removeValue(forKey: oldest)
        }
    }

    private func detectFormat(from data: Data) -> ImageFormat {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let type = CGImageSourceGetType(source) as String? else {
            return .png
        }

        let lower = type.lowercased()
        if lower.contains("png") {
            return .png
        }
        return .jpeg
    }

    private func sanitizeFilename(_ raw: String) -> String {
        let invalid = CharacterSet(charactersIn: "\\/:*?\"<>|")
        let cleaned = raw.components(separatedBy: invalid).joined(separator: "-")
        return cleaned.isEmpty ? "clipslim" : cleaned
    }

    private func safeFilenameBase(defaultName: String) -> String {
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        return sanitizeFilename("\(defaultName)-\(timestamp)")
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

    private func isMeaningfulSavings(_ result: OptimizationResult) -> Bool {
        result.optimizedSize < result.originalSize
    }
}
