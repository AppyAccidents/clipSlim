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
        let metadataPolicy: MetadataPolicy

        init(from settings: AppSettings, outputFormatOverride: ImageFormat? = nil) {
            self.quality = settings.currentQuality
            self.maxDimension = settings.currentMaxDimension
            self.stripMetadata = settings.currentStripMetadata
            self.allowTransparencyLoss = settings.currentAllowTransparencyLoss
            self.preferredFormat = settings.preferredOutputFormat
            self.preserveAlphaByForcingPNG = settings.preserveAlphaByForcingPNG
            self.outputFormatOverride = outputFormatOverride
            self.targetDimensions = nil
            self.metadataPolicy = settings.currentMetadataPolicy
        }

        init(
            quality: Double = 0.75,
            maxDimension: Int = 1920,
            stripMetadata: Bool = true,
            allowTransparencyLoss: Bool = false,
            preferredFormat: ImageFormat = .jpeg,
            preserveAlphaByForcingPNG: Bool = true,
            outputFormatOverride: ImageFormat? = nil,
            targetDimensions: (width: Int, height: Int)? = nil,
            metadataPolicy: MetadataPolicy = .stripAll
        ) {
            self.quality = quality
            self.maxDimension = maxDimension
            self.stripMetadata = stripMetadata
            self.allowTransparencyLoss = allowTransparencyLoss
            self.preferredFormat = preferredFormat
            self.preserveAlphaByForcingPNG = preserveAlphaByForcingPNG
            self.outputFormatOverride = outputFormatOverride
            self.targetDimensions = targetDimensions
            self.metadataPolicy = metadataPolicy
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
                    let maxDim = max(originalDimensions.width, originalDimensions.height)
                    let options: [CFString: Any] = [
                        kCGImageSourceCreateThumbnailFromImageAlways: true,
                        kCGImageSourceThumbnailMaxPixelSize: maxDim,
                        kCGImageSourceCreateThumbnailWithTransform: true,
                        kCGImageSourceShouldCacheImmediately: true
                    ]
                    guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
                        throw OptimizationError.invalidImageData
                    }
                    cgImage = image
                }
            }

            if cgImage.width <= 0 || cgImage.height <= 0 {
                throw OptimizationError.resizeFailed
            }

            // Normalize high bit-depth images (e.g. 10-bit HEIC → 8-bit) to prevent
            // garbled output from encoders that can't handle 16-bpc CGImages.
            let finalImage: CGImage
            if cgImage.bitsPerComponent > 8 {
                finalImage = normalizeToSRGB8(cgImage) ?? cgImage
            } else {
                finalImage = cgImage
            }

            let optimizedDimensions = (width: finalImage.width, height: finalImage.height)

            let outputData: Data
            switch outputFormat {
            case .jpeg:
                outputData = try encodeJPEG(image: finalImage, quality: config.quality, config: config, source: source)
            case .png:
                outputData = try encodePNG(image: finalImage, config: config, source: source)
            case .webp:
                outputData = try encodeWebP(image: finalImage, quality: config.quality, config: config, source: source)
            case .avif:
                outputData = try encodeAVIF(image: finalImage, quality: config.quality, config: config, source: source)
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
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(
            data: nil,
            width: safeWidth,
            height: safeHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: image.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
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

    /// Convert a high bit-depth CGImage (e.g. 16-bpc from 10-bit HEIC) to standard 8-bpc sRGB.
    private func normalizeToSRGB8(_ image: CGImage) -> CGImage? {
        let w = image.width
        let h = image.height
        guard let sRGB = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil,
                  width: w,
                  height: h,
                  bitsPerComponent: 8,
                  bytesPerRow: 0,
                  space: sRGB,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return nil
        }
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        return context.makeImage()
    }

    // MARK: - Private Helpers

    static func requiresVisibleTransparencyCheck(config: OptimizationConfig) -> Bool {
        let candidate = config.outputFormatOverride ?? config.preferredFormat
        // WebP supports alpha natively, so no transparency check needed
        return candidate == .jpeg
            && !config.allowTransparencyLoss
            && config.preserveAlphaByForcingPNG
    }

    private func decideOutputFormat(hasAlpha: Bool, config: OptimizationConfig) -> ImageFormat {
        let candidate = config.outputFormatOverride ?? config.preferredFormat
        switch candidate {
        case .jpeg:
            if hasAlpha {
                if config.allowTransparencyLoss { return .jpeg }
                return config.preserveAlphaByForcingPNG ? .png : .jpeg
            }
            return .jpeg
        case .webp:
            // WebP supports alpha, so no forced override needed
            return .webp
        case .png:
            return .png
        case .avif:
            // AVIF supports alpha, so no forced override needed
            return .avif
        }
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
            space: image.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
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

    private func filteredMetadata(from source: CGImageSource, policy: MetadataPolicy) -> [CFString: Any]? {
        guard let rawProps = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return nil
        }

        var filtered = rawProps

        if policy.shouldStripGPS {
            filtered.removeValue(forKey: kCGImagePropertyGPSDictionary)
        }

        if policy.shouldStripCameraInfo {
            filtered.removeValue(forKey: kCGImagePropertyExifDictionary)
            filtered.removeValue(forKey: kCGImagePropertyMakerAppleDictionary)
        }

        if !policy.shouldKeepCopyright && !policy.shouldKeepAuthor {
            filtered.removeValue(forKey: kCGImagePropertyIPTCDictionary)
            filtered.removeValue(forKey: kCGImagePropertyTIFFDictionary)
        } else if var iptc = filtered[kCGImagePropertyIPTCDictionary] as? [CFString: Any] {
            if !policy.shouldKeepCopyright {
                iptc.removeValue(forKey: kCGImagePropertyIPTCCopyrightNotice)
            }
            filtered[kCGImagePropertyIPTCDictionary] = iptc
        }

        return filtered
    }

    private func encodeJPEG(image: CGImage, quality: Double, config: OptimizationConfig, source: CGImageSource) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw OptimizationError.encodingFailed
        }

        var options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality,
            kCGImageDestinationEmbedThumbnail: false
        ]

        if config.metadataPolicy.effectiveStripMetadata {
            options[kCGImageDestinationOptimizeColorForSharing] = true
        } else if config.metadataPolicy.requiresSelectiveFiltering {
            if let filtered = filteredMetadata(from: source, policy: config.metadataPolicy) {
                var mergedOptions = options
                for (key, value) in filtered {
                    mergedOptions[key] = value
                }
                CGImageDestinationAddImage(destination, image, mergedOptions as CFDictionary)
                guard CGImageDestinationFinalize(destination) else {
                    throw OptimizationError.encodingFailed
                }
                return data as Data
            }
        } else {
            if let metadata = CGImageSourceCopyMetadataAtIndex(source, 0, nil) {
                let metadataOptions: [CFString: Any] = [
                    kCGImageDestinationMergeMetadata: true,
                    kCGImageDestinationMetadata: metadata
                ]
                CGImageDestinationSetProperties(destination, metadataOptions as CFDictionary)
            }
        }

        CGImageDestinationAddImage(destination, image, options as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw OptimizationError.encodingFailed
        }

        return data as Data
    }

    private func encodePNG(image: CGImage, config: OptimizationConfig, source: CGImageSource) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, UTType.png.identifier as CFString, 1, nil) else {
            throw OptimizationError.encodingFailed
        }

        var options: [CFString: Any] = [
            kCGImageDestinationEmbedThumbnail: false
        ]

        if config.metadataPolicy.effectiveStripMetadata {
            options[kCGImageDestinationOptimizeColorForSharing] = true
        } else if config.metadataPolicy.requiresSelectiveFiltering {
            if let filtered = filteredMetadata(from: source, policy: config.metadataPolicy) {
                var mergedOptions = options
                for (key, value) in filtered {
                    mergedOptions[key] = value
                }
                CGImageDestinationAddImage(destination, image, mergedOptions as CFDictionary)
                guard CGImageDestinationFinalize(destination) else {
                    throw OptimizationError.encodingFailed
                }
                return data as Data
            }
        } else {
            if let metadata = CGImageSourceCopyMetadataAtIndex(source, 0, nil) {
                let metadataOptions: [CFString: Any] = [
                    kCGImageDestinationMergeMetadata: true,
                    kCGImageDestinationMetadata: metadata
                ]
                CGImageDestinationSetProperties(destination, metadataOptions as CFDictionary)
            }
        }

        CGImageDestinationAddImage(destination, image, options as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw OptimizationError.encodingFailed
        }

        return data as Data
    }

    private func encodeWebP(image: CGImage, quality: Double, config: OptimizationConfig, source: CGImageSource) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, UTType.webP.identifier as CFString, 1, nil) else {
            // WebP encoding not available — fall back to JPEG
            return try encodeJPEG(image: image, quality: quality, config: config, source: source)
        }

        var options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality,
            kCGImageDestinationEmbedThumbnail: false
        ]

        if config.metadataPolicy.effectiveStripMetadata {
            options[kCGImageDestinationOptimizeColorForSharing] = true
        } else if config.metadataPolicy.requiresSelectiveFiltering {
            if let filtered = filteredMetadata(from: source, policy: config.metadataPolicy) {
                var mergedOptions = options
                for (key, value) in filtered {
                    mergedOptions[key] = value
                }
                CGImageDestinationAddImage(destination, image, mergedOptions as CFDictionary)
                guard CGImageDestinationFinalize(destination) else {
                    // Finalization failed — fall back to JPEG
                    return try encodeJPEG(image: image, quality: quality, config: config, source: source)
                }
                return data as Data
            }
        } else {
            if let metadata = CGImageSourceCopyMetadataAtIndex(source, 0, nil) {
                let metadataOptions: [CFString: Any] = [
                    kCGImageDestinationMergeMetadata: true,
                    kCGImageDestinationMetadata: metadata
                ]
                CGImageDestinationSetProperties(destination, metadataOptions as CFDictionary)
            }
        }

        CGImageDestinationAddImage(destination, image, options as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            // Finalization failed — fall back to JPEG
            return try encodeJPEG(image: image, quality: quality, config: config, source: source)
        }

        return data as Data
    }

    private func encodeAVIF(image: CGImage, quality: Double, config: OptimizationConfig, source: CGImageSource) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, ImageFormat.avif.utType as CFString, 1, nil) else {
            // AVIF encoding not available — fall back to JPEG
            return try encodeJPEG(image: image, quality: quality, config: config, source: source)
        }

        var options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality,
            kCGImageDestinationEmbedThumbnail: false
        ]

        if config.metadataPolicy.effectiveStripMetadata {
            options[kCGImageDestinationOptimizeColorForSharing] = true
        } else if config.metadataPolicy.requiresSelectiveFiltering {
            if let filtered = filteredMetadata(from: source, policy: config.metadataPolicy) {
                var mergedOptions = options
                for (key, value) in filtered {
                    mergedOptions[key] = value
                }
                CGImageDestinationAddImage(destination, image, mergedOptions as CFDictionary)
                guard CGImageDestinationFinalize(destination) else {
                    // Finalization failed — fall back to JPEG
                    return try encodeJPEG(image: image, quality: quality, config: config, source: source)
                }
                return data as Data
            }
        } else {
            if let metadata = CGImageSourceCopyMetadataAtIndex(source, 0, nil) {
                let metadataOptions: [CFString: Any] = [
                    kCGImageDestinationMergeMetadata: true,
                    kCGImageDestinationMetadata: metadata
                ]
                CGImageDestinationSetProperties(destination, metadataOptions as CFDictionary)
            }
        }

        CGImageDestinationAddImage(destination, image, options as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            // Finalization failed — fall back to JPEG
            return try encodeJPEG(image: image, quality: quality, config: config, source: source)
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

    /// Center-crops the image to fill the target dimensions exactly.
    /// If source is wider than target aspect ratio, crops sides. If taller, crops top/bottom.
    /// Generalizes cropToSquare to arbitrary aspect ratios.
    func cropToFill(data: Data, width targetWidth: Int, height targetHeight: Int) throws -> Data {
        guard targetWidth >= 1 && targetHeight >= 1 else { throw OptimizationError.resizeFailed }

        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw OptimizationError.invalidImageData
        }

        let srcW = cgImage.width
        let srcH = cgImage.height

        // Calculate crop rect to match target aspect ratio, centered
        let targetAspect = CGFloat(targetWidth) / CGFloat(targetHeight)
        let srcAspect = CGFloat(srcW) / CGFloat(srcH)

        let cropRect: CGRect
        if srcAspect > targetAspect {
            // Source is wider — crop sides
            let cropHeight = CGFloat(srcH)
            let cropWidth = cropHeight * targetAspect
            let originX = (CGFloat(srcW) - cropWidth) / 2
            cropRect = CGRect(x: originX, y: 0, width: cropWidth, height: cropHeight)
        } else {
            // Source is taller — crop top/bottom
            let cropWidth = CGFloat(srcW)
            let cropHeight = cropWidth / targetAspect
            let originY = (CGFloat(srcH) - cropHeight) / 2
            cropRect = CGRect(x: 0, y: originY, width: cropWidth, height: cropHeight)
        }

        guard let cropped = cgImage.cropping(to: cropRect) else {
            throw OptimizationError.resizeFailed
        }

        // Resize cropped image to exact target dimensions
        let colorSpace = cropped.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        let hasAlpha = cropped.alphaInfo != .none && cropped.alphaInfo != .noneSkipFirst && cropped.alphaInfo != .noneSkipLast
        let bitmapInfo: CGBitmapInfo = hasAlpha
            ? CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
            : CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)

        guard let context = CGContext(
            data: nil,
            width: targetWidth,
            height: targetHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            throw OptimizationError.resizeFailed
        }

        context.interpolationQuality = .high
        context.draw(cropped, in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))

        guard let resultImage = context.makeImage() else {
            throw OptimizationError.resizeFailed
        }

        let outputData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(outputData as CFMutableData, UTType.png.identifier as CFString, 1, nil) else {
            throw OptimizationError.encodingFailed
        }
        CGImageDestinationAddImage(destination, resultImage, nil)
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
            space: squareCrop.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
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
        let colorSpace = fullImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
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
