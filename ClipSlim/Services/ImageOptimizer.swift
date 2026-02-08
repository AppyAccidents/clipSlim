import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

final class ImageOptimizer: Sendable {
    
    static let shared = ImageOptimizer()
    
    private let maxInputSize: Int = 50 * 1024 * 1024 // 50 MB
    
    private init() {}
    
    struct OptimizationConfig {
        let quality: Double
        let maxDimension: Int
        let stripMetadata: Bool
        let allowTransparencyLoss: Bool
        let preferredFormat: ImageFormat?
        
        init(from settings: AppSettings) {
            self.quality = settings.currentQuality
            self.maxDimension = settings.currentMaxDimension
            self.stripMetadata = settings.currentStripMetadata
            self.allowTransparencyLoss = settings.currentAllowTransparencyLoss
            self.preferredFormat = settings.preferredOutputFormat
        }
        
        init(quality: Double = 0.75, maxDimension: Int = 1920, stripMetadata: Bool = true, allowTransparencyLoss: Bool = false, preferredFormat: ImageFormat? = nil) {
            self.quality = quality
            self.maxDimension = maxDimension
            self.stripMetadata = stripMetadata
            self.allowTransparencyLoss = allowTransparencyLoss
            self.preferredFormat = preferredFormat
        }
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
        
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw OptimizationError.invalidImageData
        }
        
        guard CGImageSourceGetCount(source) > 0 else {
            throw OptimizationError.invalidImageData
        }
        
        let originalDimensions = getImageDimensions(source: source)
        let hasAlpha = imageHasAlpha(source: source)
        let inputFormat = detectInputFormat(source: source)
        
        let outputFormat: ImageFormat
        if let preferred = config.preferredFormat {
            if preferred == .jpeg && hasAlpha && !config.allowTransparencyLoss {
                outputFormat = .png
            } else {
                outputFormat = preferred
            }
        } else if inputFormat == .heic || inputFormat == .tiff {
            if hasAlpha && !config.allowTransparencyLoss {
                outputFormat = .png
            } else {
                outputFormat = .png
            }
        } else if hasAlpha && !config.allowTransparencyLoss {
            outputFormat = .png
        } else {
            outputFormat = .jpeg
        }
        
        let cgImage: CGImage
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
    
    // MARK: - Private Helpers
    
    private func getImageDimensions(source: CGImageSource) -> (width: Int, height: Int) {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return (0, 0)
        }
        let width = properties[kCGImagePropertyPixelWidth] as? Int ?? 0
        let height = properties[kCGImagePropertyPixelHeight] as? Int ?? 0
        return (width, height)
    }
    
    enum InputFormat: String {
        case jpeg, png, heic, tiff, bmp, gif, unknown
    }
    
    private func detectInputFormat(source: CGImageSource) -> InputFormat {
        guard let utType = CGImageSourceGetType(source) as? String else {
            return .unknown
        }
        let lower = utType.lowercased()
        if lower.contains("jpeg") || lower.contains("jpg") { return .jpeg }
        if lower.contains("png") { return .png }
        if lower.contains("heic") || lower.contains("heif") { return .heic }
        if lower.contains("tiff") || lower.contains("tif") { return .tiff }
        if lower.contains("bmp") { return .bmp }
        if lower.contains("gif") { return .gif }
        return .unknown
    }
    
    private func imageHasAlpha(source: CGImageSource) -> Bool {
        guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return false
        }
        let alphaInfo = image.alphaInfo
        switch alphaInfo {
        case .first, .last, .premultipliedFirst, .premultipliedLast, .alphaOnly:
            return true
        case .none, .noneSkipFirst, .noneSkipLast:
            return false
        @unknown default:
            return false
        }
    }
    
    private func encodeJPEG(image: CGImage, quality: Double, stripMetadata: Bool, source: CGImageSource) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw OptimizationError.encodingFailed
        }
        
        var options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        
        if !stripMetadata, let sourceProperties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] {
            var metadataProperties = sourceProperties
            if stripMetadata {
                metadataProperties.removeValue(forKey: kCGImagePropertyGPSDictionary)
            }
            options[kCGImageDestinationMergeMetadata] = true
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
        
        if !stripMetadata, let sourceProperties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] {
            var metadataProperties = sourceProperties
            metadataProperties.removeValue(forKey: kCGImagePropertyGPSDictionary)
            options[kCGImageDestinationMergeMetadata] = true
        }
        
        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            throw OptimizationError.encodingFailed
        }
        
        return data as Data
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
