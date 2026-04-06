import Foundation
import CoreGraphics
import ImageIO
import AVFoundation
import UniformTypeIdentifiers

struct GIFOptimizationConfig: Sendable {
    let maxColors: Int
    let frameSkip: Int
    let maxDimension: Int
    let videoToGifFPS: Int

    init(
        maxColors: Int = 256,
        frameSkip: Int = 0,
        maxDimension: Int = 480,
        videoToGifFPS: Int = 10
    ) {
        self.maxColors = maxColors
        self.frameSkip = frameSkip
        self.maxDimension = maxDimension
        self.videoToGifFPS = videoToGifFPS
    }

    init(from settings: AppSettings) {
        self.maxColors = settings.gifMaxColors
        self.frameSkip = settings.gifFrameSkip
        self.maxDimension = settings.gifMaxDimension
        self.videoToGifFPS = settings.videoToGifFPS
    }
}

struct GIFOptimizationResult: Sendable {
    let originalSize: Int
    let optimizedSize: Int
    let frameCount: Int
    let originalFrameCount: Int
    let colorCount: Int
    let duration: TimeInterval
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
}

enum GIFOptimizationError: Error, LocalizedError {
    case inputTooLarge(Int)
    case invalidGIFData
    case noFrames
    case encodingFailed
    case videoTooLong(TimeInterval)
    case videoExtractionFailed
    case resizeFailed

    var errorDescription: String? {
        switch self {
        case .inputTooLarge(let mb): return "GIF too large: \(mb)MB exceeds 50MB limit"
        case .invalidGIFData: return "Invalid GIF data"
        case .noFrames: return "GIF contains no frames"
        case .encodingFailed: return "Failed to encode GIF"
        case .videoTooLong(let seconds): return "Video is \(Int(seconds))s, max 15s for GIF conversion"
        case .videoExtractionFailed: return "Failed to extract frames from video"
        case .resizeFailed: return "Failed to resize GIF frame"
        }
    }
}

final class GIFOptimizer: Sendable {

    static let shared = GIFOptimizer()

    private let maxInputSize: Int = 50 * 1024 * 1024 // 50 MB
    private let maxVideoToGIFDuration: TimeInterval = 15.0
    private let frameBatchSize = 50

    private init() {}

    // MARK: - Optimize GIF

    func optimizeGIF(data: Data, config: GIFOptimizationConfig) async throws -> (data: Data, result: GIFOptimizationResult) {
        let startTime = CFAbsoluteTimeGetCurrent()

        let inputSizeMB = data.count / (1024 * 1024)
        guard data.count <= maxInputSize else {
            throw GIFOptimizationError.inputTooLarge(inputSizeMB)
        }

        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw GIFOptimizationError.invalidGIFData
        }

        let originalFrameCount = CGImageSourceGetCount(source)
        guard originalFrameCount > 0 else {
            throw GIFOptimizationError.noFrames
        }

        // Read frame delays
        var frameDelays: [Double] = []
        for i in 0..<originalFrameCount {
            let delay = frameDelay(at: i, source: source)
            frameDelays.append(delay)
        }

        // Determine which frames to keep
        let keepIndices: [Int]
        if config.frameSkip > 0 {
            keepIndices = stride(from: 0, to: originalFrameCount, by: config.frameSkip + 1).map { $0 }
        } else {
            keepIndices = Array(0..<originalFrameCount)
        }

        // Calculate total duration from original
        let totalDuration = frameDelays.reduce(0, +)

        // Create output GIF
        let outputData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            outputData as CFMutableData,
            UTType.gif.identifier as CFString,
            keepIndices.count,
            nil
        ) else {
            throw GIFOptimizationError.encodingFailed
        }

        // Set GIF-level properties (loop count)
        let gifProperties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFLoopCount as String: 0 // infinite loop
            ]
        ]
        CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)

        // Process frames in batches
        var outputFrameCount = 0
        for batchStart in stride(from: 0, to: keepIndices.count, by: frameBatchSize) {
            let batchEnd = min(batchStart + frameBatchSize, keepIndices.count)
            let batch = keepIndices[batchStart..<batchEnd]

            for frameIndex in batch {
                guard let cgImage = CGImageSourceCreateImageAtIndex(source, frameIndex, nil) else {
                    continue
                }

                // Resize if needed
                let processedImage: CGImage
                if max(cgImage.width, cgImage.height) > config.maxDimension {
                    guard let resized = resizeImage(cgImage, maxDimension: config.maxDimension) else {
                        continue
                    }
                    processedImage = resized
                } else {
                    processedImage = cgImage
                }

                // Adjust delay if skipping frames
                let adjustedDelay: Double
                if config.frameSkip > 0 {
                    // Accumulate delays from skipped frames
                    let nextKeptIndex = frameIndex + config.frameSkip + 1
                    let endIndex = min(nextKeptIndex, originalFrameCount)
                    adjustedDelay = (frameIndex..<endIndex).reduce(0.0) { sum, idx in
                        sum + frameDelays[idx]
                    }
                } else {
                    adjustedDelay = frameDelays[frameIndex]
                }

                let frameProperties: [String: Any] = [
                    kCGImagePropertyGIFDictionary as String: [
                        kCGImagePropertyGIFDelayTime as String: adjustedDelay,
                        kCGImagePropertyGIFUnclampedDelayTime as String: adjustedDelay
                    ],
                    kCGImagePropertyColorModel as String: kCGImagePropertyColorModelRGB,
                    kCGImagePropertyDepth as String: 8
                ]
                CGImageDestinationAddImage(destination, processedImage, frameProperties as CFDictionary)
                outputFrameCount += 1
            }
        }

        guard outputFrameCount > 0 else {
            throw GIFOptimizationError.noFrames
        }

        guard CGImageDestinationFinalize(destination) else {
            throw GIFOptimizationError.encodingFailed
        }

        let processingTime = CFAbsoluteTimeGetCurrent() - startTime

        let result = GIFOptimizationResult(
            originalSize: data.count,
            optimizedSize: outputData.length,
            frameCount: outputFrameCount,
            originalFrameCount: originalFrameCount,
            colorCount: config.maxColors,
            duration: totalDuration,
            processingTime: processingTime
        )

        return (outputData as Data, result)
    }

    // MARK: - Video to GIF

    func videoToGIF(url: URL, config: GIFOptimizationConfig) async throws -> (data: Data, result: GIFOptimizationResult) {
        let startTime = CFAbsoluteTimeGetCurrent()

        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)

        guard durationSeconds <= maxVideoToGIFDuration else {
            throw GIFOptimizationError.videoTooLong(durationSeconds)
        }

        let originalSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0

        // Generate frames
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        // Set max size
        generator.maximumSize = CGSize(
            width: CGFloat(config.maxDimension),
            height: CGFloat(config.maxDimension)
        )

        let fps = config.videoToGifFPS
        let totalFrames = min(Int(durationSeconds * Double(fps)), 150) // Cap at 150 frames
        let frameDuration = 1.0 / Double(fps)

        var times: [CMTime] = []
        for i in 0..<totalFrames {
            let time = CMTime(seconds: Double(i) * frameDuration, preferredTimescale: 600)
            times.append(time)
        }

        // Create output GIF
        let outputData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            outputData as CFMutableData,
            UTType.gif.identifier as CFString,
            totalFrames,
            nil
        ) else {
            throw GIFOptimizationError.encodingFailed
        }

        let gifProperties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFLoopCount as String: 0
            ]
        ]
        CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)

        let frameProperties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFDelayTime as String: frameDuration,
                kCGImagePropertyGIFUnclampedDelayTime as String: frameDuration
            ]
        ]

        var frameCount = 0
        for time in times {
            do {
                let (cgImage, _) = try await generator.image(at: time)
                CGImageDestinationAddImage(destination, cgImage, frameProperties as CFDictionary)
                frameCount += 1
            } catch {
                continue // Skip frames that fail to generate
            }
        }

        guard frameCount > 0 else {
            throw GIFOptimizationError.videoExtractionFailed
        }

        guard CGImageDestinationFinalize(destination) else {
            throw GIFOptimizationError.encodingFailed
        }

        let processingTime = CFAbsoluteTimeGetCurrent() - startTime

        let result = GIFOptimizationResult(
            originalSize: originalSize,
            optimizedSize: outputData.length,
            frameCount: frameCount,
            originalFrameCount: frameCount,
            colorCount: config.maxColors,
            duration: durationSeconds,
            processingTime: processingTime
        )

        return (outputData as Data, result)
    }

    // MARK: - Private Helpers

    private func frameDelay(at index: Int, source: CGImageSource) -> Double {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [String: Any],
              let gifDict = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] else {
            return 0.1 // Default delay
        }

        if let unclampedDelay = gifDict[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double, unclampedDelay > 0 {
            return unclampedDelay
        }
        if let delay = gifDict[kCGImagePropertyGIFDelayTime as String] as? Double, delay > 0 {
            return delay
        }
        return 0.1
    }

    private func resizeImage(_ image: CGImage, maxDimension: Int) -> CGImage? {
        let width = image.width
        let height = image.height
        let maxDim = max(width, height)
        guard maxDim > maxDimension else { return image }

        let scale = Double(maxDimension) / Double(maxDim)
        let newWidth = Int(Double(width) * scale)
        let newHeight = Int(Double(height) * scale)

        guard let colorSpace = image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB) else { return nil }

        guard let context = CGContext(
            data: nil,
            width: newWidth,
            height: newHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        return context.makeImage()
    }
}
