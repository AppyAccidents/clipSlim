import Foundation
import CoreGraphics
import ImageIO
import PDFKit
import AppKit

final class PDFOptimizer: Sendable {

    static let shared = PDFOptimizer()

    private let maxPageCount = 500
    private let maxInputSize: Int = 200 * 1024 * 1024 // 200 MB
    private let maxBitmapPixels = 25_000_000

    private init() {}

    struct PDFOptimizationConfig: Sendable {
        let targetDPI: Int
        let imageQuality: Double
        let stripMetadata: Bool

        init(targetDPI: Int = 150, imageQuality: Double = 0.6, stripMetadata: Bool = true) {
            self.targetDPI = targetDPI
            self.imageQuality = imageQuality
            self.stripMetadata = stripMetadata
        }

        init(from settings: AppSettings) {
            self.targetDPI = settings.pdfTargetDPI
            self.imageQuality = settings.pdfImageQuality
            self.stripMetadata = settings.pdfStripMetadata
        }
    }

    enum Strategy: String, Sendable {
        case pdfkit
        case rasterize
        case none
    }

    enum PDFContentType: Sendable {
        case imageHeavy
        case textVector
        case mixed
    }

    struct PDFOptimizationResult: Sendable {
        let originalSize: Int
        let optimizedSize: Int
        let pageCount: Int
        let duration: TimeInterval
        let strategy: Strategy

        var savingsPercentage: Double {
            guard originalSize > 0 else { return 0 }
            return Double(originalSize - optimizedSize) / Double(originalSize) * 100
        }

        var savingsBytes: Int {
            originalSize - optimizedSize
        }

        var formattedOriginalSize: String {
            ByteCountFormatter.string(fromByteCount: Int64(originalSize), countStyle: .file)
        }

        var formattedOptimizedSize: String {
            ByteCountFormatter.string(fromByteCount: Int64(optimizedSize), countStyle: .file)
        }
    }

    func optimize(data: Data, config: PDFOptimizationConfig) throws -> (data: Data, result: PDFOptimizationResult) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let originalSize = data.count

        guard originalSize > 0 else {
            throw PDFOptimizationError.emptyData
        }

        guard originalSize <= maxInputSize else {
            throw PDFOptimizationError.fileTooLarge(originalSize)
        }

        guard let provider = CGDataProvider(data: data as CFData),
              let document = CGPDFDocument(provider) else {
            throw PDFOptimizationError.invalidPDF
        }

        let pageCount = document.numberOfPages
        guard pageCount > 0 else {
            throw PDFOptimizationError.invalidPDF
        }

        guard pageCount <= maxPageCount else {
            throw PDFOptimizationError.tooManyPages(pageCount)
        }

        let contentType = classify(document: document, data: data, pageCount: pageCount)

        var bestData = data
        var bestStrategy: Strategy = .none

        if let rewrittenData = try losslessRewrite(data: data, stripMetadata: config.stripMetadata),
           rewrittenData.count < bestData.count {
            bestData = rewrittenData
            bestStrategy = .pdfkit
        }

        if contentType != .textVector {
            let rasterizedData = try rasterizePages(document: document, pageCount: pageCount, config: config)
            if rasterizedData.count < bestData.count {
                bestData = rasterizedData
                bestStrategy = .rasterize
            }
        }

        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let result = PDFOptimizationResult(
            originalSize: originalSize,
            optimizedSize: bestData.count,
            pageCount: pageCount,
            duration: duration,
            strategy: bestStrategy
        )

        return (bestData, result)
    }

    private func losslessRewrite(data: Data, stripMetadata: Bool) throws -> Data? {
        guard let document = PDFDocument(data: data) else {
            throw PDFOptimizationError.invalidPDF
        }

        if stripMetadata {
            var attributes = document.documentAttributes ?? [:]
            let removableKeys: [PDFDocumentAttribute] = [
                .titleAttribute,
                .authorAttribute,
                .creatorAttribute,
                .producerAttribute,
                .subjectAttribute,
                .keywordsAttribute
            ]

            for key in removableKeys {
                attributes.removeValue(forKey: key)
            }

            document.documentAttributes = attributes
        }

        return document.dataRepresentation()
    }

    private func classify(document: CGPDFDocument, data: Data, pageCount: Int) -> PDFContentType {
        let bytesPerPage = data.count / max(pageCount, 1)
        let colorComplexity = sampleColorComplexity(document: document)

        if bytesPerPage >= 100_000 {
            return colorComplexity >= 90 ? .imageHeavy : .mixed
        }

        if bytesPerPage <= 50_000 {
            return colorComplexity >= 140 ? .mixed : .textVector
        }

        if colorComplexity >= 110 {
            return .imageHeavy
        }

        return .mixed
    }

    private func sampleColorComplexity(document: CGPDFDocument) -> Int {
        guard let page = document.page(at: 1) else {
            return 0
        }

        let size = CGSize(width: 200, height: 200)
        let width = Int(size.width)
        let height = Int(size.height)
        let bytesPerRow = width * 4

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return 0
        }

        context.setFillColor(CGColor.white)
        context.fill(CGRect(origin: .zero, size: size))

        let pageBox = page.getBoxRect(.mediaBox)
        guard pageBox.width > 0, pageBox.height > 0 else {
            return 0
        }

        let scale = min(size.width / pageBox.width, size.height / pageBox.height)
        let xOffset = (size.width - (pageBox.width * scale)) / 2
        let yOffset = (size.height - (pageBox.height * scale)) / 2

        context.saveGState()
        context.translateBy(x: xOffset, y: yOffset)
        context.scaleBy(x: scale, y: scale)
        context.drawPDFPage(page)
        context.restoreGState()

        guard let buffer = context.data else {
            return 0
        }

        let pixels = buffer.bindMemory(to: UInt8.self, capacity: width * height * 4)
        var quantizedColors = Set<UInt16>()

        for offset in stride(from: 0, to: width * height * 4, by: 4) {
            let r = UInt16(pixels[offset] >> 5)
            let g = UInt16(pixels[offset + 1] >> 5)
            let b = UInt16(pixels[offset + 2] >> 5)
            quantizedColors.insert((r << 6) | (g << 3) | b)

            if quantizedColors.count >= 256 {
                return quantizedColors.count
            }
        }

        return quantizedColors.count
    }

    private func rasterizePages(document: CGPDFDocument, pageCount: Int, config: PDFOptimizationConfig) throws -> Data {
        let pdfDocument = PDFDocument()
        let scale = Double(config.targetDPI) / 72.0

        for pageIndex in 1...pageCount {
            try autoreleasepool {
                guard let page = document.page(at: pageIndex) else {
                    throw PDFOptimizationError.pageRenderFailed(pageIndex)
                }

                let originalBox = page.getBoxRect(.mediaBox)
                let pixelSize = clampedPixelSize(for: originalBox, scale: scale)
                guard pixelSize.width > 0, pixelSize.height > 0 else {
                    throw PDFOptimizationError.pageRenderFailed(pageIndex)
                }

                guard let renderedImage = renderPage(page, pixelSize: pixelSize, scale: scale) else {
                    throw PDFOptimizationError.pageRenderFailed(pageIndex)
                }

                let jpegData = try encodeJPEG(image: renderedImage, quality: config.imageQuality)
                guard let imageRep = NSBitmapImageRep(data: jpegData) else {
                    throw PDFOptimizationError.encodingFailed
                }

                let image = NSImage(size: NSSize(width: originalBox.width, height: originalBox.height))
                image.addRepresentation(imageRep)

                guard let pdfPage = PDFPage(image: image) else {
                    throw PDFOptimizationError.encodingFailed
                }

                pdfDocument.insert(pdfPage, at: pdfDocument.pageCount)
            }
        }

        if config.stripMetadata {
            pdfDocument.documentAttributes = [:]
        }

        guard let data = pdfDocument.dataRepresentation() else {
            throw PDFOptimizationError.encodingFailed
        }

        return data
    }

    private func clampedPixelSize(for rect: CGRect, scale: Double) -> (width: Int, height: Int) {
        var pixelWidth = Int(rect.width * scale)
        var pixelHeight = Int(rect.height * scale)

        let requestedPixels = pixelWidth * pixelHeight
        if requestedPixels > maxBitmapPixels, requestedPixels > 0 {
            let clampScale = sqrt(Double(maxBitmapPixels) / Double(requestedPixels)) * scale
            pixelWidth = Int(rect.width * clampScale)
            pixelHeight = Int(rect.height * clampScale)
        }

        return (pixelWidth, pixelHeight)
    }

    private func renderPage(_ page: CGPDFPage, pixelSize: (width: Int, height: Int), scale: Double) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)

        guard let bitmapContext = CGContext(
            data: nil,
            width: pixelSize.width,
            height: pixelSize.height,
            bitsPerComponent: 8,
            bytesPerRow: pixelSize.width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return nil
        }

        bitmapContext.interpolationQuality = .high
        bitmapContext.setFillColor(CGColor.white)
        bitmapContext.fill(CGRect(x: 0, y: 0, width: pixelSize.width, height: pixelSize.height))
        bitmapContext.scaleBy(x: scale, y: scale)
        bitmapContext.drawPDFPage(page)

        return bitmapContext.makeImage()
    }

    private func encodeJPEG(image: CGImage, quality: Double) throws -> Data {
        let jpegData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            jpegData as CFMutableData,
            "public.jpeg" as CFString,
            1,
            nil
        ) else {
            throw PDFOptimizationError.encodingFailed
        }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality,
            kCGImageDestinationOptimizeColorForSharing: true,
            kCGImageDestinationEmbedThumbnail: false
        ]

        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw PDFOptimizationError.encodingFailed
        }

        return jpegData as Data
    }
}

enum PDFOptimizationError: LocalizedError {
    case emptyData
    case fileTooLarge(Int)
    case invalidPDF
    case tooManyPages(Int)
    case pageRenderFailed(Int)
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .emptyData:
            return "PDF data is empty"
        case .fileTooLarge(let size):
            let sizeStr = ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
            return "PDF is too large (\(sizeStr)). Maximum is 200 MB."
        case .invalidPDF:
            return "Could not read PDF document"
        case .tooManyPages(let count):
            return "PDF has too many pages (\(count)). Maximum is 500."
        case .pageRenderFailed(let page):
            return "Failed to render PDF page \(page)"
        case .encodingFailed:
            return "Failed to encode optimized PDF"
        }
    }
}
