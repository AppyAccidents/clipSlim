import XCTest
import CoreGraphics
import ImageIO
import PDFKit
import AppKit
@testable import ClipSlim

final class PDFOptimizerTests: XCTestCase {

    private let optimizer = PDFOptimizer.shared

    func testOptimizeUsesPDFKitToStripMetadata() throws {
        let source = try makeVectorPDF(
            metadata: [
                PDFDocumentAttribute.titleAttribute: "Quarterly Report",
                PDFDocumentAttribute.authorAttribute: String(repeating: "A", count: 16_384)
            ]
        )

        let (_, result) = try optimizer.optimize(
            data: source,
            config: .init(stripMetadata: true)
        )

        XCTAssertEqual(result.strategy, .pdfkit)
        XCTAssertLessThan(result.optimizedSize, result.originalSize)

        let optimized = try optimizer.optimize(
            data: source,
            config: .init(stripMetadata: true)
        ).data
        let document = try XCTUnwrap(PDFDocument(data: optimized))
        let attributes = document.documentAttributes ?? [:]

        XCTAssertNil(attributes[PDFDocumentAttribute.titleAttribute])
        XCTAssertNil(attributes[PDFDocumentAttribute.authorAttribute])
    }

    func testOptimizeDoesNotRasterizeVectorPDF() throws {
        let source = try makeVectorPDF()

        let (_, result) = try optimizer.optimize(
            data: source,
            config: .init(targetDPI: 72, imageQuality: 0.4, stripMetadata: false)
        )

        XCTAssertNotEqual(result.strategy, .rasterize)
        XCTAssertEqual(result.pageCount, 1)
    }

    func testOptimizeCanUseRasterizationForImageHeavyPDF() throws {
        let source = try makeImageHeavyPDF()

        let (_, result) = try optimizer.optimize(
            data: source,
            config: .init(targetDPI: 96, imageQuality: 0.35, stripMetadata: true)
        )

        XCTAssertEqual(result.strategy, .rasterize)
        XCTAssertLessThan(result.optimizedSize, result.originalSize)
    }

    private func makeVectorPDF(metadata: [PDFDocumentAttribute: Any] = [:]) throws -> Data {
        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data as CFMutableData) else {
            XCTFail("Failed to create PDF consumer")
            throw PDFOptimizationError.encodingFailed
        }

        var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            XCTFail("Failed to create PDF context")
            throw PDFOptimizationError.encodingFailed
        }

        context.beginPDFPage([kCGPDFContextTitle as String: "Draft"] as CFDictionary)
        context.setFillColor(CGColor.white)
        context.fill(mediaBox)
        context.setStrokeColor(red: 0.2, green: 0.4, blue: 0.7, alpha: 1)
        context.setLineWidth(2)
        context.stroke(CGRect(x: 72, y: 620, width: 468, height: 96))
        context.move(to: CGPoint(x: 72, y: 540))
        context.addLine(to: CGPoint(x: 540, y: 540))
        context.strokePath()
        context.endPDFPage()
        context.closePDF()

        guard let document = PDFDocument(data: data as Data) else {
            XCTFail("Failed to create PDF document")
            throw PDFOptimizationError.invalidPDF
        }

        if !metadata.isEmpty {
            document.documentAttributes = metadata
        }

        guard let finalData = document.dataRepresentation() else {
            XCTFail("Failed to create final PDF data")
            throw PDFOptimizationError.encodingFailed
        }

        return finalData
    }

    private func makeImageHeavyPDF() throws -> Data {
        let image = try makeNoiseImage(width: 1800, height: 2400)
        let nsImage = NSImage(cgImage: image, size: NSSize(width: 600, height: 800))
        let page = try XCTUnwrap(PDFPage(image: nsImage))
        let document = PDFDocument()
        document.insert(page, at: 0)

        guard let data = document.dataRepresentation() else {
            XCTFail("Failed to create image PDF")
            throw PDFOptimizationError.encodingFailed
        }

        return data
    }

    private func makeNoiseImage(width: Int, height: Int) throws -> CGImage {
        let bytesPerRow = width * 4
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)

        var seed: UInt64 = 0x1234_5678_9ABC_DEF0
        func nextByte() -> UInt8 {
            seed = seed &* 6364136223846793005 &+ 1
            return UInt8((seed >> 24) & 0xFF)
        }

        for offset in stride(from: 0, to: pixels.count, by: 4) {
            pixels[offset] = nextByte()
            pixels[offset + 1] = nextByte()
            pixels[offset + 2] = nextByte()
            pixels[offset + 3] = 255
        }

        let provider = CGDataProvider(data: Data(pixels) as CFData)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let provider,
              let image = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo,
                provider: provider,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
              ) else {
            XCTFail("Failed to create noise image")
            throw PDFOptimizationError.encodingFailed
        }

        return image
    }
}
