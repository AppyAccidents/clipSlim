import Foundation
import AppKit
import ImageIO

@MainActor
@Observable
final class ProcessingCoordinator {

    private(set) var isProcessing = false
    private(set) var lastError: String?

    private(set) var lastOriginalData: Data?
    private(set) var lastOptimizedData: Data?
    private(set) var lastOptimizedFormat: ImageFormat = .jpeg
    private(set) var lastOriginalFormat: ImageFormat = .png
    private(set) var lastSourceAppBundleID: String = ""

    private let optimizer = ImageOptimizer.shared
    private let pdfOptimizer = PDFOptimizer.shared
    private let log = Logger.shared

    private var optimizationCache: [String: (Data, OptimizationResult)] = [:]
    private var optimizationCacheOrder: [String] = []
    private let maxOptimizationCacheEntries = 10

    // MARK: - Dependencies (set by AppViewModel)

    var settings: AppSettings!
    var clipboardWatcher: ClipboardWatcher!
    var overlayService: OverlayService!
    var notificationService: NotificationService { NotificationService.shared }
    var folderWatcher: FolderWatcher!
    var dropZoneService: DropZoneService!
    var ignoreCache: IgnoreCache!

    var contextAwareService: ContextAwareService?
    var statsService: StatsService?
    var clipboardHistoryService: ClipboardHistoryService?
    var duplicateHashService: DuplicateHashService?

    var onEventRecorded: ((OptimizationEvent) -> Void)?
    var currentFrontmostBundleID: () -> String = { "" }
    var matchesFocusBundle: (String, [String]) -> Bool = { _, _ in false }

    // MARK: - Public

    func clearLastError() {
        lastError = nil
    }

    func processImageData(
        _ data: Data,
        source: OptimizationEvent.Source,
        fileName: String?,
        outputFormatOverride: ImageFormat?,
        targetDimensions: (width: Int, height: Int)?,
        sourceBundleID: String?
    ) async {
        if let fileType = OptimizableFileType.from(data: data), fileType.isPDF {
            await processClipboardPDF(data, sourceBundleID: sourceBundleID)
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
            let sourceBundleID = sourceBundleID ?? currentFrontmostBundleID()
            lastSourceAppBundleID = sourceBundleID
            let excludedBundleIDs = Set(settings.excludedBundleIDs)
            let focusedBundleIDs = settings.focusBundleIDs

            if excludedBundleIDs.contains(sourceBundleID) { return }

            let isFocusMode = source == .clipboard && settings.focusModeEnabled && matchesFocusBundle(sourceBundleID, focusedBundleIDs)

            let sourceHash = ClipboardWatcher.hash(data)
            if source == .clipboard && ignoreCache.contains(sourceHash) {
                log.clipboard("Skipped image due to ignore cache")
                return
            }

            let info = await Task.detached(priority: .utility) {
                ImageOptimizer.shared.inspect(data: data) ?? .init(dimensions: (0, 0), hasAlpha: false)
            }.value

            // F1: Context-aware preset override
            var effectivePreset = settings.selectedPreset
            var pendingSuggestionPresetName: String?
            var pendingSuggestionAppName: String?
            if let ctx = contextAwareService,
               let suggestion = ctx.suggestedPreset(for: sourceBundleID) {
                if suggestion.autoApply {
                    effectivePreset = suggestion.preset
                    log.app("Context-aware: auto-applying \(suggestion.preset.rawValue) for \(sourceBundleID)")
                } else {
                    // Show suggestion banner in overlay
                    let mapping = ctx.mappings.first { $0.bundleID == sourceBundleID }
                    pendingSuggestionPresetName = suggestion.preset.rawValue
                    pendingSuggestionAppName = mapping?.appName ?? sourceBundleID.components(separatedBy: ".").last
                }
            }

            // F2: Smart format selection
            var effectiveFormat = outputFormatOverride
            if effectiveFormat == nil && settings.smartFormatEnabled {
                let classification = await Task.detached(priority: .utility) {
                    ImageClassifier.shared.classify(data: data)
                }.value
                let config = FormatSelector.FormatSelectorConfig(from: settings)
                effectiveFormat = FormatSelector.shared.recommendFormat(
                    classification: classification,
                    hasAlpha: info.hasAlpha,
                    config: config
                )
                log.app("Smart format: \(classification.rawValue) -> \(effectiveFormat?.rawValue ?? "default")")
            }

            let quality: Double
            if settings.overridePresetQuality {
                quality = settings.globalQualityValue
            } else {
                quality = effectivePreset == .custom ? settings.customQuality : effectivePreset.quality
            }
            let maxDimension = effectivePreset == .custom ? settings.customMaxDimension : effectivePreset.maxDimension
            let stripMetadata = effectivePreset == .custom ? settings.customStripMetadata : effectivePreset.stripMetadata
            let allowTransparencyLoss = effectivePreset == .custom ? settings.customAllowTransparencyLoss : effectivePreset.allowTransparencyLoss

            // F4: Pipeline step overrides
            let enabledSteps = settings.enabledPipelineSteps
            let finalQuality = enabledSteps.contains(.compress) ? quality : 1.0
            let finalMaxDimension = enabledSteps.contains(.resize) ? maxDimension : Int.max
            let finalStripMetadata = enabledSteps.contains(.stripMetadata) ? stripMetadata : false
            let finalFormat = enabledSteps.contains(.convertFormat) ? effectiveFormat : nil

            let effectiveMetadataPolicy: MetadataPolicy = finalStripMetadata ? settings.currentMetadataPolicy : .keepAll
            let config = ImageOptimizer.OptimizationConfig(
                quality: finalQuality,
                maxDimension: finalMaxDimension,
                stripMetadata: finalStripMetadata,
                allowTransparencyLoss: allowTransparencyLoss,
                preferredFormat: settings.preferredOutputFormat,
                preserveAlphaByForcingPNG: settings.preserveAlphaByForcingPNG,
                outputFormatOverride: finalFormat,
                targetDimensions: targetDimensions,
                metadataPolicy: effectiveMetadataPolicy
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

            // Lossless skip guard: if optimized is larger or equal, use original
            if settings.selectedPreset == .lossless && result.optimizedSize >= result.originalSize {
                log.app("Lossless mode: optimized (\(result.optimizedSize)) >= original (\(result.originalSize)), skipping")
                return
            }

            var bestData = optimizedData
            var bestResult = result
            let isForcedTransformation = outputFormatOverride != nil || targetDimensions != nil

            if !isMeaningfulSavings(result), !isForcedTransformation {
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
                        targetDimensions: targetDimensions,
                        metadataPolicy: effectiveMetadataPolicy
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

            // F3: Quality Guard — compute SSIM
            var qualityScore: Double?
            var qualityBelowThreshold = false
            if settings.qualityGuardEnabled && !isForcedTransformation {
                let ssim = await Task.detached(priority: .utility) {
                    QualityScorer.shared.computeSSIM(original: data, optimized: bestData)
                }.value
                qualityScore = ssim
                qualityBelowThreshold = ssim < settings.qualityGuardThreshold
                if qualityBelowThreshold {
                    log.app("Quality Guard: SSIM \(String(format: "%.3f", ssim)) below threshold \(String(format: "%.2f", settings.qualityGuardThreshold))")
                }
            }

            // F6: Duplicate detection via ContentHashRecord (cross-session)
            var isDuplicate = false
            var duplicateOptimizedData: Data?
            if !isForcedTransformation, let hashService = duplicateHashService {
                let existing = hashService.findRecord(hash: sourceHash)
                if let existing {
                    isDuplicate = true
                    // Try to load previously optimized data
                    if let path = existing.optimizedFileURL {
                        duplicateOptimizedData = try? Data(contentsOf: URL(fileURLWithPath: path))
                    }
                    hashService.touchRecord(existing)
                    log.app("Duplicate detected: hash \(sourceHash.prefix(8))… seen at \(existing.firstSeenAt)")
                } else {
                    // Record this hash for future duplicate detection
                    hashService.recordHash(sourceHash, optimizedSize: bestResult.optimizedSize)
                }
            }

            if source == .clipboard {
                clipboardWatcher.writeToPasteboard(data: bestData, format: bestResult.format)
                if !isFocusMode {
                    var item = OverlayItem(
                        originalData: data,
                        optimizedData: bestData,
                        result: bestResult,
                        formatOverrideSelection: bestResult.format,
                        sourceAppBundleID: sourceBundleID
                    )
                    item.suggestedPresetName = pendingSuggestionPresetName
                    item.suggestedAppName = pendingSuggestionAppName
                    item.qualityScore = qualityScore
                    item.qualityBelowThreshold = qualityBelowThreshold
                    item.isDuplicate = isDuplicate
                    item.duplicateOptimizedData = duplicateOptimizedData
                    overlayService.show(item: item)
                }

                // F10: Record to clipboard history
                clipboardHistoryService?.addEntry(
                    originalData: data,
                    optimizedData: bestData,
                    originalSize: bestResult.originalSize,
                    optimizedSize: bestResult.optimizedSize,
                    format: bestResult.format,
                    sourceBundleID: sourceBundleID
                )
            }

            let event = OptimizationEvent(
                timestamp: Date(),
                source: source,
                result: bestResult,
                fileName: fileName
            )
            onEventRecorded?(event)

            // F5: Persist to SwiftData
            statsService?.recordEvent(
                source: source.rawValue,
                originalSize: bestResult.originalSize,
                optimizedSize: bestResult.optimizedSize,
                format: bestResult.format.rawValue,
                duration: bestResult.duration,
                originalWidth: bestResult.originalDimensions.width,
                originalHeight: bestResult.originalDimensions.height,
                optimizedWidth: bestResult.optimizedDimensions.width,
                optimizedHeight: bestResult.optimizedDimensions.height,
                fileName: fileName,
                sourceBundleID: sourceBundleID,
                contentHash: sourceHash
            )

            if settings.notificationsEnabled {
                notificationService.sendOptimizationNotification(result: bestResult, source: source)
            }

            Task {
                await SaveCoordinator.shared.saveToDisk(
                    originalData: data,
                    optimizedData: bestData,
                    format: bestResult.format,
                    fileName: fileName,
                    sourceURL: nil,
                    settings: settings
                )
            }

            log.app("Optimization complete: \(bestResult.formattedOriginalSize) -> \(bestResult.formattedOptimizedSize) (\(String(format: "%.1f", bestResult.savingsPercentage))%)")
        } catch {
            lastError = error.localizedDescription
            log.error("Optimization failed: \(error.localizedDescription)", category: "optimizer")
        }
    }

    func processFileURL(_ url: URL) async {
        let fileType = OptimizableFileType.from(url: url)

        if case .pdf = fileType {
            await processPDFFileURL(url)
            return
        }

        do {
            // F9: Evaluate folder rules
            let rulesData = settings.folderRulesData
            if let jsonData = rulesData.data(using: .utf8),
               let rules = try? JSONDecoder().decode([FolderRule].self, from: jsonData),
               !rules.isEmpty {
                let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
                let ext = url.pathExtension.lowercased()
                let format: ImageFormat = ext == "png" ? .png : (ext == "webp" ? .webp : .jpeg)
                let context = RuleEvaluator.FileContext(
                    fileSize: fileSize, format: format, fileName: url.lastPathComponent,
                    hasAlpha: false, width: 0, height: 0
                )
                if let action = RuleEvaluator.shared.evaluate(rules: rules, context: context) {
                    if case .skip = action {
                        log.folder("Folder rule: skipping \(url.lastPathComponent)")
                        return
                    }
                    // Other actions can be applied to modify config below
                }
            }

            let config = ImageOptimizer.OptimizationConfig(from: settings)
            let (data, optimizedData, result) = try await OptimizationDispatch.run {
                let data = try Data(contentsOf: url)
                let (optimizedData, result) = try await ImageOptimizer.shared.optimize(data: data, config: config)
                return (data, optimizedData, result)
            }

            // Lossless skip guard: if optimized is larger or equal, use original
            if settings.selectedPreset == .lossless && result.optimizedSize >= result.originalSize {
                log.folder("Lossless mode: no savings for \(url.lastPathComponent), skipping")
                return
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
            onEventRecorded?(event)

            if settings.notificationsEnabled {
                notificationService.sendOptimizationNotification(result: result, source: .folder)
            }

            Task {
                await SaveCoordinator.shared.saveToDisk(
                    originalData: data,
                    optimizedData: optimizedData,
                    format: result.format,
                    fileName: url.lastPathComponent,
                    sourceURL: url,
                    settings: settings
                )
            }

            log.folder("Optimized \(url.lastPathComponent) -> \(outputURL.lastPathComponent)")
        } catch {
            log.error("Folder optimization failed for \(url.lastPathComponent): \(error.localizedDescription)", category: "folder")
        }
    }

    func processPDFFileURL(_ url: URL) async {
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
            onEventRecorded?(event)

            if settings.notificationsEnabled {
                notificationService.sendOptimizationNotification(result: result, source: .folder)
            }

            log.folder("Optimized PDF \(url.lastPathComponent) -> \(outputURL.lastPathComponent) (\(pdfResult.pageCount) pages)")
        } catch {
            log.error("PDF folder optimization failed for \(url.lastPathComponent): \(error.localizedDescription)", category: "folder")
        }
    }

    func processClipboardPDF(_ data: Data, sourceBundleID: String?) async {
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
            let isFocusMode = settings.focusModeEnabled && matchesFocusBundle(bundleID, settings.focusBundleIDs)

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
            onEventRecorded?(event)

            if settings.notificationsEnabled {
                notificationService.sendOptimizationNotification(result: result, source: .clipboard)
            }

            Task {
                await SaveCoordinator.shared.saveToDisk(
                    originalData: data,
                    optimizedData: optimizedData,
                    format: .jpeg,
                    fileName: "clipboard.pdf",
                    sourceURL: nil,
                    settings: settings
                )
            }

            log.app("PDF optimization complete: \(pdfResult.formattedOriginalSize) -> \(pdfResult.formattedOptimizedSize) (\(pdfResult.pageCount) pages)")
        } catch {
            lastError = error.localizedDescription
            log.error("Clipboard PDF optimization failed: \(error.localizedDescription)", category: "optimizer")
        }
    }

    func processDroppedFiles(_ urls: [URL]) async {
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
                    onEventRecorded?(event)

                    dropZoneService.updateItem(id: itemID, state: .completed(
                        savedBytes: pdfResult.savingsBytes,
                        savingsPercent: pdfResult.savingsPercentage
                    ))

                case .video:
                    dropZoneService.updateItem(id: itemID, state: .failed("Video optimization coming soon"))
                    continue

                case .gif:
                    dropZoneService.updateItem(id: itemID, state: .failed("GIF optimization coming soon"))
                    continue

                case .svg:
                    dropZoneService.updateItem(id: itemID, state: .failed("SVG optimization coming soon"))
                    continue

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
                    onEventRecorded?(event)

                    dropZoneService.updateItem(id: itemID, state: .completed(
                        savedBytes: result.savingsBytes,
                        savingsPercent: result.savingsPercentage
                    ))
                }

                if settings.notificationsEnabled {
                    notificationService.sendOptimizationNotification(
                        result: OptimizationResult(
                            originalSize: 0, optimizedSize: 0, format: .jpeg,
                            duration: 0, originalDimensions: (0, 0), optimizedDimensions: (0, 0)
                        ),
                        source: .dropZone
                    )
                }
            } catch {
                dropZoneService.updateItem(id: itemID, state: .failed(error.localizedDescription))
                log.error("Drop zone optimization failed for \(url.lastPathComponent): \(error.localizedDescription)", category: "dropzone")
            }
        }
    }

    // MARK: - Helpers

    func isMeaningfulSavings(_ result: OptimizationResult) -> Bool {
        result.optimizedSize < result.originalSize
    }

    func detectFormat(from data: Data) -> ImageFormat {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let type = CGImageSourceGetType(source) as String? else {
            return .png
        }

        let lower = type.lowercased()
        if lower.contains("png") { return .png }
        return .jpeg
    }

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
}
