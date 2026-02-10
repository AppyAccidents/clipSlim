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
    let iapService = IAPService()
    let ignoreCache = IgnoreCache()

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
    private let notificationService = NotificationService.shared
    private let ruleEngine = RuleEngine()
    private let log = Logger.shared

    private var hotKeyRef1: EventHotKeyRef?
    private var hotKeyRef2: EventHotKeyRef?

    private var optimizationCache: [String: (Data, OptimizationResult)] = [:]
    private var optimizationCacheOrder: [String] = []
    private let maxOptimizationCacheEntries = 10

    private var onboardingWindow: NSWindow?
    private var onboardingCloseObserver: NSObjectProtocol?
    private var hasStartedServices = false
    private var lastKnownFrontmostBundleID: String = ""

    init() {
        setupClipboardWatcher()
        setupFolderWatcher()
        setupOverlayActions()
        setupFrontmostAppTracking()
        notificationService.requestAuthorization()
        registerGlobalHotkeys()
        Task { @MainActor in
            self.startServices()
        }
    }

    // MARK: - Public

    var pauseStatusText: String {
        if shouldPauseClipboardForFocus() {
            return "Paused by Focus mode"
        }
        guard let until = settings.pauseUntil, settings.isPausedNow else { return "Active" }
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return "Paused until \(formatter.string(from: until))"
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
        refreshPauseState()
        if settings.folderWatchEnabled && (!settings.isPausedNow || !settings.pauseFolderWatcher) {
            startFolderWatcher()
        }
    }

    func stopServices() {
        clipboardWatcher.stop()
        folderWatcher.stop()
        hasStartedServices = false
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
        let focusPaused = shouldPauseClipboardForFocus()
        if settings.isPausedNow || focusPaused {
            clipboardWatcher.stop()
            if settings.pauseFolderWatcher && settings.isPausedNow {
                folderWatcher.stop()
            }
        } else {
            settings.pauseUntil = nil
            if settings.clipboardWatchEnabled {
                clipboardWatcher.start()
            }
            if settings.folderWatchEnabled {
                startFolderWatcher()
            }
        }
    }

    func pauseFor(minutes: Int) {
        settings.pauseUntil = Date().addingTimeInterval(TimeInterval(minutes * 60))
        refreshPauseState()
    }

    func pauseFor(hours: Int) {
        settings.pauseUntil = Date().addingTimeInterval(TimeInterval(hours * 3600))
        refreshPauseState()
    }

    func pauseUntilTomorrow() {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date().addingTimeInterval(24 * 3600)
        settings.pauseUntil = calendar.startOfDay(for: tomorrow)
        refreshPauseState()
    }

    func resumeFromPause() {
        settings.pauseUntil = nil
        refreshPauseState()
    }

    func addWatchFolders() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.message = "Choose one or more folders to watch for new images"
        panel.prompt = "Add Folders"

        if panel.runModal() == .OK {
            var folders = settings.watchedFolders
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
        }
    }

    func removeWatchFolder(_ folder: WatchedFolder) {
        settings.watchedFolders.removeAll { $0.id == folder.id }
        if settings.folderWatchEnabled {
            startFolderWatcher()
        }
    }

    func completeOnboarding(
        preferredFormat: ImageFormat,
        optimizationIntensity: OptimizationIntensity,
        folders: [WatchedFolder]
    ) {
        settings.preferredOutputFormat = preferredFormat
        settings.applyOptimizationIntensity(optimizationIntensity)
        settings.watchedFolders = folders
        settings.clipboardWatchEnabled = true
        settings.pauseUntil = nil
        if !folders.isEmpty {
            settings.folderWatchEnabled = true
        } else {
            settings.folderWatchEnabled = false
        }
        settings.markOnboardingCompleted()
        refreshPauseState()
        if settings.folderWatchEnabled {
            startFolderWatcher()
        }
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
        guard let original = lastOriginalData, let optimized = lastOptimizedData else { return }

        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose where to save original and optimized images"
        panel.prompt = "Save"

        guard panel.runModal() == .OK, let base = panel.url else { return }

        let safeBase = safeFilenameBase(defaultName: "clipslim")
        let originalURL = base.appendingPathComponent("\(safeBase)-original.\(lastOriginalFormat.fileExtension)")
        let optimizedURL = base.appendingPathComponent("\(safeBase)-optimized.\(lastOptimizedFormat.fileExtension)")

        Task {
            do {
                try await Task.detached(priority: .utility) {
                    try original.write(to: originalURL, options: .atomic)
                    try optimized.write(to: optimizedURL, options: .atomic)
                }.value
                log.app("Saved original and optimized pair via Save As")
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

    func openSettingsWindow() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    // MARK: - Private Setup

    private func setupClipboardWatcher() {
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
        overlayService.onUndo = { [weak self] in self?.undoLastOptimization() }
        overlayService.onSaveAs = { [weak self] in self?.saveLastPairAs() }
        overlayService.onRemoveClipboardImage = { [weak self] in self?.removeImageFromClipboard() }
        overlayService.onApplyFormatOverride = { [weak self] format in self?.applyOneOffFormatOverride(format) }
        overlayService.onApplyResizeOverride = { [weak self] width, height in
            self?.applyOneOffResizeOverride(width: width, height: height)
        }
        overlayService.onOpenSettings = { [weak self] in self?.openSettingsWindow() }
        overlayService.onIgnoreImage = { [weak self] in self?.ignoreCurrentImage() }
        overlayService.onIgnoreApp = { [weak self] in self?.ignoreCurrentApp() }
    }

    private func setupFrontmostAppTracking() {
        updateFrontmostBundleID()
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateFrontmostBundleID()
                self?.refreshPauseState()
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
            guard let self else { return }
            self.onboardingWindow = nil
            if let observer = self.onboardingCloseObserver {
                NotificationCenter.default.removeObserver(observer)
                self.onboardingCloseObserver = nil
            }
        }
    }

    private func startFolderWatcher() {
        let folders = settings.watchedFolders
        guard !folders.isEmpty else {
            log.folder("No watched folders configured")
            return
        }
        folderWatcher.start(folders: folders)
    }

    // MARK: - Global Hotkeys

    private func registerGlobalHotkeys() {
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

    private func saveToDisk(originalData: Data, optimizedData: Data, format: ImageFormat, fileName: String?) async {
        guard settings.saveToDisk else { return }

        let basePath: String
        if settings.saveFolderPath.isEmpty {
            let pictures = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first!
            basePath = pictures.appendingPathComponent("ClipSlim").path
        } else {
            basePath = settings.saveFolderPath
        }

        let originalsDir = (basePath as NSString).appendingPathComponent("Originals")
        let optimizedDir = (basePath as NSString).appendingPathComponent("Optimized")

        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let baseName = fileName ?? "clipboard-\(timestamp)"
        let nameWithoutExt = sanitizeFilename((baseName as NSString).deletingPathExtension)
        let origExt = (baseName as NSString).pathExtension.isEmpty ? "png" : (baseName as NSString).pathExtension

        let originalPath = (originalsDir as NSString).appendingPathComponent("\(nameWithoutExt).\(origExt)")
        let optimizedPath = (optimizedDir as NSString).appendingPathComponent("\(nameWithoutExt).\(format.fileExtension)")

        do {
            try await Task.detached(priority: .utility) {
                try FileManager.default.createDirectory(atPath: originalsDir, withIntermediateDirectories: true, attributes: nil)
                try FileManager.default.createDirectory(atPath: optimizedDir, withIntermediateDirectories: true, attributes: nil)
                try originalData.write(to: URL(fileURLWithPath: originalPath), options: .atomic)
                try optimizedData.write(to: URL(fileURLWithPath: optimizedPath), options: .atomic)
            }.value
            log.app("Saved original/optimized pair to configured save folder")
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

            if settings.excludedBundleIDs.contains(sourceBundleID) {
                return
            }

            if source == .clipboard && settings.focusModeEnabled && matchesFocusBundle(sourceBundleID) {
                return
            }

            let sourceHash = ClipboardWatcher.hash(data)
            if source == .clipboard && ignoreCache.contains(sourceHash) {
                log.clipboard("Skipped image due to ignore cache")
                return
            }

            let info = await Task.detached(priority: .utility) {
                ImageOptimizer.shared.inspect(data: data) ?? .init(dimensions: (0, 0), hasAlpha: false)
            }.value
            let ruleContext = RuleEvaluationContext(
                frontmostBundleID: sourceBundleID,
                byteSize: data.count,
                dimensions: info.dimensions,
                hasAlpha: info.hasAlpha
            )
            let decision = ruleEngine.evaluate(rules: settings.rules, context: ruleContext)
            guard decision.shouldOptimize else {
                log.app("Skipping due to matched rule: \(decision.matchedRuleName ?? "skip")")
                return
            }

            let effectiveFormat = outputFormatOverride ?? decision.formatOverride
            let effectivePreset = decision.presetOverride ?? settings.selectedPreset
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
                let optimizedTuple = try await Task.detached(priority: .userInitiated) {
                    try await ImageOptimizer.shared.optimize(data: data, config: config)
                }.value
                optimizedData = optimizedTuple.data
                result = optimizedTuple.result
                cacheOptimization(cacheKey: cacheKey, data: optimizedData, result: result)
            }

            var bestData = optimizedData
            var bestResult = result
            let isForcedTransformation = outputFormatOverride != nil || decision.formatOverride != nil || targetDimensions != nil

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
                        let tuple = try await Task.detached(priority: .userInitiated) {
                            try await ImageOptimizer.shared.optimize(data: data, config: alternateConfig)
                        }.value
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
                overlayService.show(item: OverlayItem(
                    originalData: data,
                    optimizedData: bestData,
                    result: bestResult,
                    formatOverrideSelection: bestResult.format,
                    sourceAppBundleID: sourceBundleID
                ))
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
                await saveToDisk(originalData: data, optimizedData: bestData, format: bestResult.format, fileName: fileName)
            }

            log.app("Optimization complete: \(bestResult.formattedOriginalSize) -> \(bestResult.formattedOptimizedSize) (\(String(format: "%.1f", bestResult.savingsPercentage))%)")
        } catch {
            lastError = error.localizedDescription
            log.error("Optimization failed: \(error.localizedDescription)", category: "optimizer")
        }
    }

    private func processFileURL(_ url: URL) async {
        do {
            let config = ImageOptimizer.OptimizationConfig(from: settings)
            let (data, optimizedData, result) = try await Task.detached(priority: .userInitiated) {
                let data = try Data(contentsOf: url)
                let (optimizedData, result) = try await ImageOptimizer.shared.optimize(data: data, config: config)
                return (data, optimizedData, result)
            }.value

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
                await saveToDisk(originalData: data, optimizedData: optimizedData, format: result.format, fileName: url.lastPathComponent)
            }

            log.folder("Optimized \(url.lastPathComponent) -> \(outputURL.lastPathComponent)")
        } catch {
            log.error("Folder optimization failed for \(url.lastPathComponent): \(error.localizedDescription)", category: "folder")
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

    private func matchesFocusBundle(_ bundleID: String) -> Bool {
        guard !bundleID.isEmpty else { return false }
        for focused in settings.focusBundleIDs {
            if focused == "*" { return true }
            if bundleID == focused { return true }
            if bundleID.hasPrefix(focused) { return true }
        }
        return false
    }

    private func shouldPauseClipboardForFocus() -> Bool {
        guard settings.focusModeEnabled else { return false }
        return matchesFocusBundle(currentFrontmostBundleID())
    }

    private func isMeaningfulSavings(_ result: OptimizationResult) -> Bool {
        result.optimizedSize < result.originalSize
    }
}
