import Foundation
import AVFoundation

enum VideoCodec: String, Codable, CaseIterable {
    case h264 = "H.264"
    case hevc = "H.265"

    var exportPreset: String {
        switch self {
        case .h264: return AVAssetExportPresetHighestQuality
        case .hevc: return AVAssetExportPresetHEVCHighestQuality
        }
    }

    var fileType: AVFileType {
        return .mp4
    }
}

enum VideoMaxResolution: Int, Codable, CaseIterable {
    case p1080 = 1080
    case p1440 = 1440
    case p2160 = 2160

    var label: String {
        switch self {
        case .p1080: return "1080p"
        case .p1440: return "1440p"
        case .p2160: return "4K"
        }
    }
}

struct VideoOptimizationConfig: Sendable {
    let codec: VideoCodec
    let quality: Double
    let maxResolution: VideoMaxResolution
    let stripMetadata: Bool

    init(
        codec: VideoCodec = .h264,
        quality: Double = 0.7,
        maxResolution: VideoMaxResolution = .p1080,
        stripMetadata: Bool = true
    ) {
        self.codec = codec
        self.quality = quality
        self.maxResolution = maxResolution
        self.stripMetadata = stripMetadata
    }

    init(from settings: AppSettings) {
        self.codec = VideoCodec(rawValue: settings.videoCodecRaw) ?? .h264
        self.quality = settings.videoQuality
        self.maxResolution = VideoMaxResolution(rawValue: settings.videoMaxResolution) ?? .p1080
        self.stripMetadata = settings.videoStripMetadata
    }
}

struct VideoOptimizationResult: Sendable {
    let originalSize: Int
    let optimizedSize: Int
    let duration: TimeInterval
    let codec: VideoCodec
    let resolutionWidth: Int
    let resolutionHeight: Int
    let originalBitrate: Int
    let optimizedBitrate: Int
    let processingTime: TimeInterval

    var savingsPercentage: Double {
        guard originalSize > 0 else { return 0 }
        return Double(originalSize - optimizedSize) / Double(originalSize) * 100
    }

    var savingsBytes: Int {
        return originalSize - optimizedSize
    }

    var formattedOriginalSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(originalSize), countStyle: .file)
    }

    var formattedOptimizedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(optimizedSize), countStyle: .file)
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }

    var formattedResolution: String {
        "\(resolutionWidth)x\(resolutionHeight)"
    }
}

enum VideoOptimizationError: Error, LocalizedError {
    case inputTooLarge(Int)
    case invalidInput
    case exportFailed(String)
    case timeout
    case noVideoTrack
    case exportSessionCreationFailed

    var errorDescription: String? {
        switch self {
        case .inputTooLarge(let mb): return "Video too large: \(mb)MB exceeds 500MB limit"
        case .invalidInput: return "Invalid video data"
        case .exportFailed(let reason): return "Export failed: \(reason)"
        case .timeout: return "Video export timed out"
        case .noVideoTrack: return "No video track found"
        case .exportSessionCreationFailed: return "Could not create export session"
        }
    }
}

final class VideoOptimizer: Sendable {

    static let shared = VideoOptimizer()

    private let maxInputSize: Int = 500 * 1024 * 1024 // 500 MB

    private init() {}

    func optimize(inputURL: URL, config: VideoOptimizationConfig) async throws -> (URL, VideoOptimizationResult) {
        let startTime = CFAbsoluteTimeGetCurrent()

        // Validate input size
        let attributes = try FileManager.default.attributesOfItem(atPath: inputURL.path)
        let fileSize = attributes[.size] as? Int ?? 0
        let fileSizeMB = fileSize / (1024 * 1024)
        guard fileSize <= maxInputSize else {
            throw VideoOptimizationError.inputTooLarge(fileSizeMB)
        }

        let asset = AVURLAsset(url: inputURL)

        // Get video track info
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw VideoOptimizationError.noVideoTrack
        }

        let naturalSize = try await videoTrack.load(.naturalSize)
        let estimatedDataRate = try await videoTrack.load(.estimatedDataRate)
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)

        let originalWidth = Int(naturalSize.width)
        let originalHeight = Int(naturalSize.height)
        let originalBitrate = Int(estimatedDataRate)

        // Determine export preset based on resolution constraint and codec
        let exportPresetName = resolveExportPreset(
            codec: config.codec,
            originalWidth: originalWidth,
            originalHeight: originalHeight,
            maxResolution: config.maxResolution
        )

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: exportPresetName) else {
            throw VideoOptimizationError.exportSessionCreationFailed
        }

        // Create temp output file
        let tempDir = FileManager.default.temporaryDirectory
        let outputURL = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true

        if config.stripMetadata {
            exportSession.metadataItemFilter = AVMetadataItemFilter.forSharing()
        }

        // Calculate timeout: 60s base + 1s per MB above 100MB
        let timeoutSeconds: TimeInterval = 60.0 + max(0, Double(fileSizeMB - 100))

        // Export with timeout
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                await exportSession.export()
                if exportSession.status != .completed {
                    let errorMsg = exportSession.error?.localizedDescription ?? "Unknown error"
                    throw VideoOptimizationError.exportFailed(errorMsg)
                }
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeoutSeconds * 1_000_000_000))
                exportSession.cancelExport()
                throw VideoOptimizationError.timeout
            }

            // Wait for first to complete (export success or timeout)
            try await group.next()
            group.cancelAll()
        }

        // Read output size
        let outputAttributes = try FileManager.default.attributesOfItem(atPath: outputURL.path)
        let outputSize = outputAttributes[.size] as? Int ?? 0

        // Determine output resolution
        let outputAsset = AVURLAsset(url: outputURL)
        var outputWidth = originalWidth
        var outputHeight = originalHeight
        if let outputTrack = try? await outputAsset.loadTracks(withMediaType: .video).first {
            let outputNaturalSize = try await outputTrack.load(.naturalSize)
            outputWidth = Int(outputNaturalSize.width)
            outputHeight = Int(outputNaturalSize.height)
        }

        let optimizedBitrate: Int
        if durationSeconds > 0 {
            optimizedBitrate = Int(Double(outputSize * 8) / durationSeconds)
        } else {
            optimizedBitrate = 0
        }

        let processingTime = CFAbsoluteTimeGetCurrent() - startTime

        let result = VideoOptimizationResult(
            originalSize: fileSize,
            optimizedSize: outputSize,
            duration: durationSeconds,
            codec: config.codec,
            resolutionWidth: outputWidth,
            resolutionHeight: outputHeight,
            originalBitrate: originalBitrate,
            optimizedBitrate: optimizedBitrate,
            processingTime: processingTime
        )

        return (outputURL, result)
    }

    /// Resolve the best AVAssetExportSession preset name given codec and resolution constraints.
    private func resolveExportPreset(
        codec: VideoCodec,
        originalWidth: Int,
        originalHeight: Int,
        maxResolution: VideoMaxResolution
    ) -> String {
        let maxDim = maxResolution.rawValue
        let largerDimension = max(originalWidth, originalHeight)

        switch codec {
        case .hevc:
            if largerDimension <= 1080 || maxDim <= 1080 {
                return AVAssetExportPresetHEVC1920x1080
            } else if largerDimension <= 1440 || maxDim <= 1440 {
                return AVAssetExportPresetHEVC3840x2160 // No 1440p preset, use 4K and let resolution clamp
            } else {
                return AVAssetExportPresetHEVC3840x2160
            }
        case .h264:
            if largerDimension <= 1080 || maxDim <= 1080 {
                return AVAssetExportPreset1920x1080
            } else {
                return AVAssetExportPresetHighestQuality
            }
        }
    }
}
