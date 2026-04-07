import Foundation
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers

/// Applies text or image watermarks to image data using CoreGraphics.
/// Sendable singleton — safe for concurrent use from any isolation domain.
final class WatermarkService: Sendable {
    static let shared = WatermarkService()
    /// Maximum number of tiles to prevent runaway rendering.
    private static let maxTiles = 100

    private init() {}

    // MARK: - Public API

    /// Applies the watermark described by `config` to `imageData`.
    /// Returns original data unchanged if config is disabled or input is invalid.
    func apply(to imageData: Data, config: WatermarkConfig) throws -> Data {
        guard config.enabled else { return imageData }

        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return imageData
        }

        let width = cgImage.width
        let height = cgImage.height

        // Skip very small images
        guard width >= 64 && height >= 64 else { return imageData }

        let colorSpace = cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            throw WatermarkError.contextCreationFailed
        }

        let imageRect = CGRect(x: 0, y: 0, width: width, height: height)
        context.draw(cgImage, in: imageRect)

        switch config.type {
        case .text:
            try drawTextWatermark(in: context, config: config, imageWidth: CGFloat(width), imageHeight: CGFloat(height))
        case .image:
            try drawImageWatermark(in: context, config: config, imageWidth: CGFloat(width), imageHeight: CGFloat(height))
        }

        guard let resultImage = context.makeImage() else {
            throw WatermarkError.renderFailed
        }

        // Detect original format for output
        let uti = CGImageSourceGetType(source) as String? ?? UTType.png.identifier
        let outputData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(outputData as CFMutableData, uti as CFString, 1, nil) else {
            throw WatermarkError.encodingFailed
        }
        CGImageDestinationAddImage(destination, resultImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw WatermarkError.encodingFailed
        }

        return outputData as Data
    }

    // MARK: - Text Watermark

    private func drawTextWatermark(in context: CGContext, config: WatermarkConfig, imageWidth: CGFloat, imageHeight: CGFloat) throws {
        guard !config.text.isEmpty else { return }

        let font = CTFontCreateWithName(config.fontName as CFString, config.fontSize, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: config.color.cgColor
        ]
        let attrString = NSAttributedString(string: config.text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attrString)
        let textBounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
        let textWidth = ceil(textBounds.width)
        let textHeight = ceil(textBounds.height)

        if config.tilingEnabled {
            let positions = tilingPositions(
                imageWidth: imageWidth,
                imageHeight: imageHeight,
                itemWidth: textWidth,
                itemHeight: textHeight,
                spacing: config.tilingSpacing
            )
            for point in positions {
                context.saveGState()
                context.textPosition = CGPoint(x: point.x, y: point.y)
                CTLineDraw(line, context)
                context.restoreGState()
            }
        } else {
            let origin = config.position.origin(
                imageWidth: imageWidth,
                imageHeight: imageHeight,
                watermarkWidth: textWidth,
                watermarkHeight: textHeight,
                margin: config.margin
            )
            context.textPosition = origin
            CTLineDraw(line, context)
        }
    }

    // MARK: - Image Watermark

    private func drawImageWatermark(in context: CGContext, config: WatermarkConfig, imageWidth: CGFloat, imageHeight: CGFloat) throws {
        guard !config.imagePath.isEmpty else { return }

        let url = URL(fileURLWithPath: config.imagePath)
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let watermarkImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw WatermarkError.watermarkImageLoadFailed
        }

        let wmWidth = CGFloat(watermarkImage.width)
        let wmHeight = CGFloat(watermarkImage.height)

        if config.tilingEnabled {
            let positions = tilingPositions(
                imageWidth: imageWidth,
                imageHeight: imageHeight,
                itemWidth: wmWidth,
                itemHeight: wmHeight,
                spacing: config.tilingSpacing
            )
            for point in positions {
                context.saveGState()
                context.setAlpha(config.imageOpacity)
                context.draw(watermarkImage, in: CGRect(x: point.x, y: point.y, width: wmWidth, height: wmHeight))
                context.restoreGState()
            }
        } else {
            let origin = config.position.origin(
                imageWidth: imageWidth,
                imageHeight: imageHeight,
                watermarkWidth: wmWidth,
                watermarkHeight: wmHeight,
                margin: config.margin
            )
            context.saveGState()
            context.setAlpha(config.imageOpacity)
            context.draw(watermarkImage, in: CGRect(x: origin.x, y: origin.y, width: wmWidth, height: wmHeight))
            context.restoreGState()
        }
    }

    // MARK: - Tiling

    private func tilingPositions(imageWidth: CGFloat, imageHeight: CGFloat, itemWidth: CGFloat, itemHeight: CGFloat, spacing: CGFloat) -> [CGPoint] {
        var positions: [CGPoint] = []
        let stepX = itemWidth + spacing
        let stepY = itemHeight + spacing
        guard stepX > 0 && stepY > 0 else { return [] }

        var y: CGFloat = 0
        while y < imageHeight && positions.count < Self.maxTiles {
            var x: CGFloat = 0
            while x < imageWidth && positions.count < Self.maxTiles {
                positions.append(CGPoint(x: x, y: y))
                x += stepX
            }
            y += stepY
        }
        return positions
    }
}

// MARK: - Errors

enum WatermarkError: Error, LocalizedError {
    case contextCreationFailed
    case renderFailed
    case encodingFailed
    case watermarkImageLoadFailed

    var errorDescription: String? {
        switch self {
        case .contextCreationFailed: return "Failed to create graphics context for watermark"
        case .renderFailed: return "Failed to render watermarked image"
        case .encodingFailed: return "Failed to encode watermarked image"
        case .watermarkImageLoadFailed: return "Failed to load watermark image from path"
        }
    }
}
