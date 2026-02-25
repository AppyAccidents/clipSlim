import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

final class ImageOptimizer: Sendable {

    static let shared = ImageOptimizer()

    private let maxInputSize: Int = 50 * 1024 * 1024 // 50 MB

    private init() {}

    struct ImageInfo {
        let dimensions: (width: Int, height: Int)
        let hasAlpha: Bool
    }

    struct OptimizationConfig {
        let quality: Double
        let maxDimension: Int
        let stripMetadata: Bool
        let allowTransparencyLoss: Bool
        let preferredFormat: ImageFormat
        let preserveAlphaByForcingPNG: Bool
        let outputFormatOverride: ImageFormat?
        let targetDimensions: (width: Int, height: Int)?

        init(from settings: AppSettings, outputFormatOverride: ImageFormat? = nil) {
            self.quality = settings.currentQuality
            self.maxDimension = settings.currentMaxDimension
            self.stripMetadata = settings.currentStripMetadata
            self.allowTransparencyLoss = settings.currentAllowTransparencyLoss
            self.preferredFormat = settings.preferredOutputFormat
            self.preserveAlphaByForcingPNG = settings.preserveAlphaByForcingPNG
            self.outputFormatOverride = outputFormatOverride
            self.targetDimensions = nil
        }

        init(
            quality: Double = 0.75,
            maxDimension: Int = 1920,
            stripMetadata: Bool = true,
            allowTransparencyLoss: Bool = false,
            preferredFormat: ImageFormat = .jpeg,
            preserveAlphaByForcingPNG: Bool = true,
            outputFormatOverride: ImageFormat? = nil,
            targetDimensions: (width: Int, height: Int)? = nil
        ) {
            self.quality = quality
            self.maxDimension = maxDimension
            self.stripMetadata = stripMetadata
            self.allowTransparencyLoss = allowTransparencyLoss
            self.preferredFormat = preferredFormat
            self.preserveAlphaByForcingPNG = preserveAlphaByForcingPNG
            self.outputFormatOverride = outputFormatOverride
            self.targetDimensions = targetDimensions
        }
    }

    func inspect(data: Data) -> ImageInfo? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(source) > 0 else {
            return nil
        }

        return ImageInfo(
            dimensions: getImageDimensions(source: source),
            hasAlpha: imageHasVisibleTransparency(source: source)
        )
    }

    func optimize(data: Data, config: OptimizationConfig) async throws -> (data: Data, result: OptimizationResult) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let originalSize = data.count

        guard originalSize > 0 else {
            throw OptimizationError.emptyData
        }

        guard originalSize <= maxInputSize else {
            throw OptimizationError.fileTooLarge(originalSize)
        }

        return try autoreleasepool {
            guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
                throw OptimizationError.invalidImageData
            }

            guard CGImageSourceGetCount(source) > 0 else {
                throw OptimizationError.invalidImageData
            }

            let originalDimensions = getImageDimensions(source: source)
            let hasAlpha: Bool
            if Self.requiresVisibleTransparencyCheck(config: config) {
                hasAlpha = imageHasVisibleTransparency(source: source)
            } else {
                hasAlpha = false
            }
            let outputFormat = decideOutputFormat(hasAlpha: hasAlpha, config: config)

            let cgImage: CGImage
            if let targetDimensions = config.targetDimensions {
                guard let sourceImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                    throw OptimizationError.invalidImageData
                }
                cgImage = try resizeImage(
                    image: sourceImage,
                    width: targetDimensions.width,
                    height: targetDimensions.height
                )
            } else {
                let needsResize = originalDimensions.width > config.maxDimension || originalDimensions.height > config.maxDimension
                if needsResize {
                    let options: [CFString: Any] = [
                        kCGImageSourceCreateThumbnailFromImageAlways: true,
                        kCGImageSourceThumbnailMaxPixelSize: config.maxDimension,
                        kCGImageSourceCreateThumbnailWithTransform: true,
                        kCGImageSourceShouldCacheImmediately: true
                    ]
                    guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
                        throw OptimizationError.resizeFailed
                    }
                    cgImage = thumbnail
                } else {
                    guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                        throw OptimizationError.invalidImageData
                    }
                    cgImage = image
                }
            }

            if cgImage.width <= 0 || cgImage.height <= 0 {
                throw OptimizationError.resizeFailed
            }

            let optimizedDimensions = (width: cgImage.width, height: cgImage.height)

            let outputData: Data
            switch outputFormat {
            case .jpeg:
                outputData = try encodeJPEG(image: cgImage, quality: config.quality, stripMetadata: config.stripMetadata, source: source)
            case .png:
                outputData = try encodePNG(image: cgImage, stripMetadata: config.stripMetadata, source: source)
            }

            let duration = CFAbsoluteTimeGetCurrent() - startTime

            let result = OptimizationResult(
                originalSize: originalSize,
                optimizedSize: outputData.count,
                format: outputFormat,
                duration: duration,
                originalDimensions: originalDimensions,
                optimizedDimensions: optimizedDimensions
            )

            return (outputData, result)
        }
    }

    private func resizeImage(image: CGImage, width: Int, height: Int) throws -> CGImage {
        let safeWidth = max(1, width)
        let safeHeight = max(1, height)
        let bytesPerPixel = 4
        let bytesPerRow = safeWidth * bytesPerPixel
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(
            data: nil,
            width: safeWidth,
            height: safeHeight,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo
        ) else {
            throw OptimizationError.resizeFailed
        }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: safeWidth, height: safeHeight))

        guard let resized = context.makeImage() else {
            throw OptimizationError.resizeFailed
        }

        return resized
    }

    // MARK: - Private Helpers

    static func requiresVisibleTransparencyCheck(config: OptimizationConfig) -> Bool {
        let candidate = config.outputFormatOverride ?? config.preferredFormat
        return candidate == .jpeg
            && !config.allowTransparencyLoss
            && config.preserveAlphaByForcingPNG
    }

    private func decideOutputFormat(hasAlpha: Bool, config: OptimizationConfig) -> ImageFormat {
        let candidate = config.outputFormatOverride ?? config.preferredFormat
        if candidate == .jpeg && hasAlpha {
            if config.allowTransparencyLoss {
                return .jpeg
            }
            return config.preserveAlphaByForcingPNG ? .png : .jpeg
        }
        return candidate
    }

    private func getImageDimensions(source: CGImageSource) -> (width: Int, height: Int) {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return (0, 0)
        }
        let width = properties[kCGImagePropertyPixelWidth] as? Int ?? 0
        let height = properties[kCGImagePropertyPixelHeight] as? Int ?? 0
        return (width, height)
    }

    // We treat "alpha" as visible transparency, not just alpha-channel presence.
    // This prevents fully opaque PNGs with an alpha channel from being forced to PNG.
    private func imageHasVisibleTransparency(source: CGImageSource) -> Bool {
        guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return false
        }

        let alphaInfo = image.alphaInfo
        switch alphaInfo {
        case .none, .noneSkipFirst, .noneSkipLast:
            return false
        default:
            break
        }

        let sampleMaxSide = 256
        let sampleWidth = max(1, min(image.width, sampleMaxSide))
        let sampleHeight = max(1, min(image.height, sampleMaxSide))
        let bytesPerPixel = 4
        let bitsPerComponent = 8
        let bytesPerRow = sampleWidth * bytesPerPixel

        guard let context = CGContext(
            data: nil,
            width: sampleWidth,
            height: sampleHeight,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return true
        }

        context.interpolationQuality = .none
        context.setBlendMode(.copy)
        context.draw(image, in: CGRect(x: 0, y: 0, width: sampleWidth, height: sampleHeight))

        guard let data = context.data else {
            return true
        }

        let buffer = data.bindMemory(to: UInt8.self, capacity: sampleHeight * bytesPerRow)
        let alphaOffset = 3
        for y in 0..<sampleHeight {
            let rowStart = y * bytesPerRow
            for x in 0..<sampleWidth {
                let alpha = buffer[rowStart + (x * bytesPerPixel) + alphaOffset]
                if alpha < 255 {
                    return true
                }
            }
        }
        return false
    }

    private func encodeJPEG(image: CGImage, quality: Double, stripMetadata: Bool, source: CGImageSource) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw OptimizationError.encodingFailed
        }

        var options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]

        if !stripMetadata,
           let sourceProperties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] {
            options[kCGImageDestinationMetadata] = sourceProperties
        }

        CGImageDestinationAddImage(destination, image, options as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw OptimizationError.encodingFailed
        }

        return data as Data
    }

    private func encodePNG(image: CGImage, stripMetadata: Bool, source: CGImageSource) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, UTType.png.identifier as CFString, 1, nil) else {
            throw OptimizationError.encodingFailed
        }

        var options: [CFString: Any] = [:]

        if !stripMetadata,
           let sourceProperties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] {
            options[kCGImageDestinationMetadata] = sourceProperties
        }

        CGImageDestinationAddImage(destination, image, options as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw OptimizationError.encodingFailed
        }

        return data as Data
    }

    // MARK: - Crop

    func cropToSquare(data: Data, side: Int) throws -> Data {
        guard side >= 1 else { throw OptimizationError.resizeFailed }

        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw OptimizationError.invalidImageData
        }

        let w = cgImage.width
        let h = cgImage.height
        let clampedSide = min(side, min(w, h))

        let originX = (w - clampedSide) / 2
        let originY = (h - clampedSide) / 2
        let cropRect = CGRect(x: originX, y: originY, width: clampedSide, height: clampedSide)

        guard let cropped = cgImage.cropping(to: cropRect) else {
            throw OptimizationError.resizeFailed
        }

        let outputData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(outputData as CFMutableData, UTType.png.identifier as CFString, 1, nil) else {
            throw OptimizationError.encodingFailed
        }
        CGImageDestinationAddImage(destination, cropped, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw OptimizationError.encodingFailed
        }
        return outputData as Data
    }

    func cropToCircle(data: Data, radius: Int) throws -> Data {
        guard radius >= 1 else { throw OptimizationError.resizeFailed }

        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw OptimizationError.invalidImageData
        }

        let w = cgImage.width
        let h = cgImage.height
        let diameter = radius * 2
        let clampedDiameter = min(diameter, min(w, h))

        let originX = (w - clampedDiameter) / 2
        let originY = (h - clampedDiameter) / 2
        let cropRect = CGRect(x: originX, y: originY, width: clampedDiameter, height: clampedDiameter)

        guard let squareCrop = cgImage.cropping(to: cropRect) else {
            throw OptimizationError.resizeFailed
        }

        let size = CGSize(width: clampedDiameter, height: clampedDiameter)
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let context = CGContext(
            data: nil,
            width: clampedDiameter,
            height: clampedDiameter,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            throw OptimizationError.resizeFailed
        }

        let circleRect = CGRect(origin: .zero, size: size)
        context.addEllipse(in: circleRect)
        context.clip()
        context.draw(squareCrop, in: circleRect)

        guard let circularImage = context.makeImage() else {
            throw OptimizationError.resizeFailed
        }

        let outputData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(outputData as CFMutableData, UTType.png.identifier as CFString, 1, nil) else {
            throw OptimizationError.encodingFailed
        }
        CGImageDestinationAddImage(destination, circularImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw OptimizationError.encodingFailed
        }
        return outputData as Data
    }

    // MARK: - Dominant Colors

    /// Extracts the top N dominant colors from image data using pixel bucketing.
    /// Fast CoreGraphics-only implementation; scales to 80×80 thumbnail internally.
    func dominantColors(data: Data, maxColors: Int = 3) -> [(cgColor: CGColor, hex: String)] {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let fullImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return []
        }

        // Scale down to 80×80 for speed
        let thumbSize = 80
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let ctx = CGContext(
            data: nil, width: thumbSize, height: thumbSize,
            bitsPerComponent: 8, bytesPerRow: thumbSize * 4,
            space: colorSpace, bitmapInfo: bitmapInfo.rawValue
        ) else { return [] }
        ctx.draw(fullImage, in: CGRect(x: 0, y: 0, width: thumbSize, height: thumbSize))
        guard let thumbImage = ctx.makeImage() else { return [] }

        let w = thumbImage.width
        let h = thumbImage.height
        let byteCount = w * h * 4
        var pixelBuffer = [UInt8](repeating: 0, count: byteCount)
        guard let pixCtx = CGContext(
            data: &pixelBuffer, width: w, height: h,
            bitsPerComponent: 8, bytesPerRow: w * 4,
            space: colorSpace, bitmapInfo: bitmapInfo.rawValue
        ) else { return [] }
        pixCtx.draw(thumbImage, in: CGRect(x: 0, y: 0, width: w, height: h))

        // Quantize each RGB channel to 5 bits (32 levels) for bucketing
        var buckets: [Int32: (count: Int, rSum: Int, gSum: Int, bSum: Int)] = [:]
        for i in stride(from: 0, to: byteCount, by: 4) {
            let r = pixelBuffer[i]
            let g = pixelBuffer[i + 1]
            let b = pixelBuffer[i + 2]
            let a = pixelBuffer[i + 3]
            guard a > 128 else { continue } // skip transparent pixels
            let key = Int32(r >> 3) << 10 | Int32(g >> 3) << 5 | Int32(b >> 3)
            if var bucket = buckets[key] {
                bucket.count += 1
                bucket.rSum += Int(r)
                bucket.gSum += Int(g)
                bucket.bSum += Int(b)
                buckets[key] = bucket
            } else {
                buckets[key] = (count: 1, rSum: Int(r), gSum: Int(g), bSum: Int(b))
            }
        }

        let sorted = buckets.values.sorted { $0.count > $1.count }.prefix(maxColors)
        return sorted.map { bucket in
            let n = max(bucket.count, 1)
            let r = Double(bucket.rSum / n) / 255.0
            let g = Double(bucket.gSum / n) / 255.0
            let b = Double(bucket.bSum / n) / 255.0
            let cgColor = CGColor(red: r, green: g, blue: b, alpha: 1.0)
            let hex = String(format: "#%02X%02X%02X",
                Int(r * 255), Int(g * 255), Int(b * 255))
            return (cgColor: cgColor, hex: hex)
        }
    }
}

// MARK: - Errors
enum OptimizationError: LocalizedError {
    case emptyData
    case fileTooLarge(Int)
    case invalidImageData
    case resizeFailed
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .emptyData:
            return "Image data is empty"
        case .fileTooLarge(let size):
            let sizeStr = ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
            return "Image is too large (\(sizeStr)). Maximum is 50 MB."
        case .invalidImageData:
            return "Could not decode image data"
        case .resizeFailed:
            return "Failed to resize image"
        case .encodingFailed:
            return "Failed to encode optimized image"
        }
    }
}
