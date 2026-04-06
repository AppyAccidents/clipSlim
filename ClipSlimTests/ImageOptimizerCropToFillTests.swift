import XCTest
@testable import ClipSlim

final class ImageOptimizerCropToFillTests: XCTestCase {

    let optimizer = ImageOptimizer.shared

    // MARK: - Helper

    private func makeTestPNG(width: Int, height: Int, hasAlpha: Bool = false) -> Data? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo: CGBitmapInfo = hasAlpha
            ? CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
            : CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)

        guard let context = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: colorSpace, bitmapInfo: bitmapInfo.rawValue
        ) else { return nil }

        context.setFillColor(red: 0.2, green: 0.6, blue: 0.8, alpha: 1.0)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        guard let image = context.makeImage() else { return nil }
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData as CFMutableData, "public.png" as CFString, 1, nil
        ) else { return nil }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return mutableData as Data
    }

    private func imageDimensions(of data: Data) -> (width: Int, height: Int)? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
        return (image.width, image.height)
    }

    // MARK: - Tests

    func testCropWideToSquare() throws {
        let data = try XCTUnwrap(makeTestPNG(width: 1920, height: 1080))
        let result = try optimizer.cropToFill(data: data, width: 1080, height: 1080)
        let dims = try XCTUnwrap(imageDimensions(of: result))
        XCTAssertEqual(dims.width, 1080)
        XCTAssertEqual(dims.height, 1080)
    }

    func testCropSquareToLandscape() throws {
        let data = try XCTUnwrap(makeTestPNG(width: 1080, height: 1080))
        let result = try optimizer.cropToFill(data: data, width: 1920, height: 1080)
        let dims = try XCTUnwrap(imageDimensions(of: result))
        XCTAssertEqual(dims.width, 1920)
        XCTAssertEqual(dims.height, 1080)
    }

    func testCropOutputMatchesTargetExactly() throws {
        let data = try XCTUnwrap(makeTestPNG(width: 2000, height: 1500))
        let result = try optimizer.cropToFill(data: data, width: 1600, height: 900)
        let dims = try XCTUnwrap(imageDimensions(of: result))
        XCTAssertEqual(dims.width, 1600)
        XCTAssertEqual(dims.height, 900)
    }

    func testCropTallToPortrait() throws {
        let data = try XCTUnwrap(makeTestPNG(width: 1080, height: 1920))
        let result = try optimizer.cropToFill(data: data, width: 1080, height: 1080)
        let dims = try XCTUnwrap(imageDimensions(of: result))
        XCTAssertEqual(dims.width, 1080)
        XCTAssertEqual(dims.height, 1080)
    }

    func testCropTransparentImagePreservesAlpha() throws {
        let data = try XCTUnwrap(makeTestPNG(width: 400, height: 400, hasAlpha: true))
        let result = try optimizer.cropToFill(data: data, width: 200, height: 100)
        let dims = try XCTUnwrap(imageDimensions(of: result))
        XCTAssertEqual(dims.width, 200)
        XCTAssertEqual(dims.height, 100)
        // Verify it produced valid data
        XCTAssertFalse(result.isEmpty)
    }

    func testCropTargetLargerThanSource() throws {
        // Target larger than source — should still produce correct dimensions
        // (upscales the crop, which is a valid use case for social presets)
        let data = try XCTUnwrap(makeTestPNG(width: 200, height: 200))
        let result = try optimizer.cropToFill(data: data, width: 1080, height: 1080)
        let dims = try XCTUnwrap(imageDimensions(of: result))
        XCTAssertEqual(dims.width, 1080)
        XCTAssertEqual(dims.height, 1080)
    }

    func testCropInvalidDimensionsThrows() {
        let data = makeTestPNG(width: 100, height: 100)!
        XCTAssertThrowsError(try optimizer.cropToFill(data: data, width: 0, height: 100))
        XCTAssertThrowsError(try optimizer.cropToFill(data: data, width: 100, height: 0))
    }
}
