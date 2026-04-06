import XCTest
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
@testable import ClipSlim

final class GIFOptimizerTests: XCTestCase {

    let optimizer = GIFOptimizer.shared

    // MARK: - Helper

    /// Creates a multi-frame GIF programmatically
    private func makeTestGIF(
        width: Int = 100,
        height: Int = 100,
        frameCount: Int = 5,
        delay: Double = 0.1,
        hasAlpha: Bool = false
    ) -> Data? {
        let outputData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            outputData as CFMutableData,
            UTType.gif.identifier as CFString,
            frameCount,
            nil
        ) else { return nil }

        let gifProperties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFLoopCount as String: 0
            ]
        ]
        CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo: UInt32 = hasAlpha
            ? CGImageAlphaInfo.premultipliedLast.rawValue
            : CGImageAlphaInfo.noneSkipLast.rawValue

        for i in 0..<frameCount {
            guard let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ) else { return nil }

            // Vary color per frame for realism
            let red = CGFloat(i) / CGFloat(frameCount)
            context.setFillColor(red: red, green: 0.5, blue: 0.8, alpha: 1.0)
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))

            guard let image = context.makeImage() else { return nil }

            let frameProperties: [String: Any] = [
                kCGImagePropertyGIFDictionary as String: [
                    kCGImagePropertyGIFDelayTime as String: delay,
                    kCGImagePropertyGIFUnclampedDelayTime as String: delay
                ]
            ]
            CGImageDestinationAddImage(destination, image, frameProperties as CFDictionary)
        }

        guard CGImageDestinationFinalize(destination) else { return nil }
        return outputData as Data
    }

    // MARK: - Optimize GIF Tests

    func testOptimizePreservesFrameCount() async throws {
        guard let gifData = makeTestGIF(frameCount: 5) else {
            XCTFail("Failed to create test GIF")
            return
        }

        let config = GIFOptimizationConfig(maxColors: 256, frameSkip: 0, maxDimension: 480)
        let (_, result) = try await optimizer.optimizeGIF(data: gifData, config: config)

        XCTAssertEqual(result.frameCount, 5)
        XCTAssertEqual(result.originalFrameCount, 5)
    }

    func testOptimizeReducesFrameCountWithSkip() async throws {
        guard let gifData = makeTestGIF(frameCount: 10) else {
            XCTFail("Failed to create test GIF")
            return
        }

        // frameSkip=1 means keep every other frame
        let config = GIFOptimizationConfig(maxColors: 256, frameSkip: 1, maxDimension: 480)
        let (_, result) = try await optimizer.optimizeGIF(data: gifData, config: config)

        XCTAssertEqual(result.originalFrameCount, 10)
        XCTAssertEqual(result.frameCount, 5) // 0, 2, 4, 6, 8
    }

    func testOptimizeResizesLargeFrames() async throws {
        guard let gifData = makeTestGIF(width: 800, height: 600, frameCount: 3) else {
            XCTFail("Failed to create test GIF")
            return
        }

        let config = GIFOptimizationConfig(maxColors: 256, frameSkip: 0, maxDimension: 200)
        let (outputData, result) = try await optimizer.optimizeGIF(data: gifData, config: config)

        XCTAssertFalse(outputData.isEmpty)
        XCTAssertEqual(result.frameCount, 3)
        // Verify output is smaller due to resize
        XCTAssertLessThan(result.optimizedSize, result.originalSize)
    }

    func testOptimizeSingleFrame() async throws {
        guard let gifData = makeTestGIF(frameCount: 1) else {
            XCTFail("Failed to create test GIF")
            return
        }

        let config = GIFOptimizationConfig(maxColors: 256, frameSkip: 0, maxDimension: 480)
        let (outputData, result) = try await optimizer.optimizeGIF(data: gifData, config: config)

        XCTAssertFalse(outputData.isEmpty)
        XCTAssertEqual(result.frameCount, 1)
        XCTAssertEqual(result.originalFrameCount, 1)
    }

    func testOptimizePreservesDelay() async throws {
        guard let gifData = makeTestGIF(frameCount: 3, delay: 0.2) else {
            XCTFail("Failed to create test GIF")
            return
        }

        let config = GIFOptimizationConfig(maxColors: 256, frameSkip: 0, maxDimension: 480)
        let (outputData, result) = try await optimizer.optimizeGIF(data: gifData, config: config)

        XCTAssertFalse(outputData.isEmpty)
        XCTAssertEqual(result.duration, 0.6, accuracy: 0.01)
    }

    func testOptimizeTransparentFrames() async throws {
        guard let gifData = makeTestGIF(frameCount: 3, hasAlpha: true) else {
            XCTFail("Failed to create test GIF")
            return
        }

        let config = GIFOptimizationConfig(maxColors: 256, frameSkip: 0, maxDimension: 480)
        let (outputData, _) = try await optimizer.optimizeGIF(data: gifData, config: config)

        XCTAssertFalse(outputData.isEmpty)
    }

    func testInvalidGIFDataThrows() async {
        let garbage = Data("not a gif".utf8)
        let config = GIFOptimizationConfig()

        do {
            _ = try await optimizer.optimizeGIF(data: garbage, config: config)
            XCTFail("Should have thrown for invalid data")
        } catch {
            XCTAssertTrue(error is GIFOptimizationError)
        }
    }

    func testEmptyDataThrows() async {
        let config = GIFOptimizationConfig()

        do {
            _ = try await optimizer.optimizeGIF(data: Data(), config: config)
            XCTFail("Should have thrown for empty data")
        } catch {
            XCTAssertTrue(error is GIFOptimizationError)
        }
    }

    // MARK: - Result Properties

    func testResultSavingsCalculation() {
        let result = GIFOptimizationResult(
            originalSize: 10000,
            optimizedSize: 6000,
            frameCount: 5,
            originalFrameCount: 10,
            colorCount: 128,
            duration: 1.0,
            processingTime: 0.5
        )

        XCTAssertEqual(result.savingsPercentage, 40.0, accuracy: 0.01)
        XCTAssertEqual(result.savingsBytes, 4000)
    }
}
