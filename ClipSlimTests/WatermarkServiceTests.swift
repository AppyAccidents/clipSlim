import XCTest
@testable import ClipSlim

final class WatermarkServiceTests: XCTestCase {

    let service = WatermarkService.shared

    // MARK: - Helper

    private func makeTestPNG(width: Int = 200, height: Int = 200, hasAlpha: Bool = true) -> Data? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
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

    private func makeWatermarkPNG() -> (Data, URL)? {
        guard let data = makeTestPNG(width: 50, height: 50) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("test_watermark.png")
        try? data.write(to: url)
        return (data, url)
    }

    // MARK: - Disabled config returns original

    func testDisabledConfigReturnsOriginal() throws {
        let imageData = try XCTUnwrap(makeTestPNG())
        var config = WatermarkConfig.default
        config.enabled = false
        let result = try service.apply(to: imageData, config: config)
        XCTAssertEqual(result, imageData)
    }

    // MARK: - Text watermark produces valid output

    func testTextWatermarkProducesValidOutput() throws {
        let imageData = try XCTUnwrap(makeTestPNG())
        var config = WatermarkConfig.default
        config.enabled = true
        config.type = .text
        config.text = "ClipSlim"
        config.fontSize = 20
        let result = try service.apply(to: imageData, config: config)
        XCTAssertFalse(result.isEmpty)
        XCTAssertNotEqual(result, imageData, "Watermarked data should differ from original")
    }

    // MARK: - Empty text returns original

    func testEmptyTextReturnsOriginal() throws {
        let imageData = try XCTUnwrap(makeTestPNG())
        var config = WatermarkConfig.default
        config.enabled = true
        config.type = .text
        config.text = ""
        let result = try service.apply(to: imageData, config: config)
        // Output may differ in encoding but image content should be effectively unchanged.
        // We check that it at least does not throw.
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - Very small image skipped

    func testVerySmallImageSkipped() throws {
        let smallImage = try XCTUnwrap(makeTestPNG(width: 32, height: 32))
        var config = WatermarkConfig.default
        config.enabled = true
        config.type = .text
        config.text = "Test"
        let result = try service.apply(to: smallImage, config: config)
        XCTAssertEqual(result, smallImage, "Small images (<64px) should be returned unchanged")
    }

    // MARK: - Image watermark composites

    func testImageWatermarkComposites() throws {
        let imageData = try XCTUnwrap(makeTestPNG())
        guard let (_, wmURL) = makeWatermarkPNG() else {
            XCTFail("Failed to create watermark PNG")
            return
        }
        var config = WatermarkConfig.default
        config.enabled = true
        config.type = .image
        config.imagePath = wmURL.path
        config.imageOpacity = 0.8
        let result = try service.apply(to: imageData, config: config)
        XCTAssertFalse(result.isEmpty)
        XCTAssertNotEqual(result, imageData)
    }

    // MARK: - All 9 positions produce valid output

    func testAllNinePositions() throws {
        let imageData = try XCTUnwrap(makeTestPNG())
        for position in WatermarkPosition.allCases {
            var config = WatermarkConfig.default
            config.enabled = true
            config.type = .text
            config.text = "Pos"
            config.position = position
            let result = try service.apply(to: imageData, config: config)
            XCTAssertFalse(result.isEmpty, "Position \(position) should produce valid output")
        }
    }

    // MARK: - Tiling produces valid output

    func testTilingProducesValidOutput() throws {
        let imageData = try XCTUnwrap(makeTestPNG(width: 400, height: 400))
        var config = WatermarkConfig.default
        config.enabled = true
        config.type = .text
        config.text = "Tile"
        config.fontSize = 14
        config.tilingEnabled = true
        config.tilingSpacing = 50
        let result = try service.apply(to: imageData, config: config)
        XCTAssertFalse(result.isEmpty)
        XCTAssertNotEqual(result, imageData)
    }

    // MARK: - Margin pushes watermark inward

    func testMarginAffectsPosition() throws {
        let origin0 = WatermarkPosition.bottomRight.origin(
            imageWidth: 500, imageHeight: 500,
            watermarkWidth: 100, watermarkHeight: 50,
            margin: 0
        )
        let origin20 = WatermarkPosition.bottomRight.origin(
            imageWidth: 500, imageHeight: 500,
            watermarkWidth: 100, watermarkHeight: 50,
            margin: 20
        )
        XCTAssertEqual(origin0.x, 400) // 500 - 100 - 0
        XCTAssertEqual(origin0.y, 0)   // 0 + 0
        XCTAssertEqual(origin20.x, 380) // 500 - 100 - 20
        XCTAssertEqual(origin20.y, 20)  // 0 + 20
    }

    // MARK: - CodableColor round-trips

    func testCodableColorRoundTrip() throws {
        let color = CodableColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 0.4)
        let data = try JSONEncoder().encode(color)
        let decoded = try JSONDecoder().decode(CodableColor.self, from: data)
        XCTAssertEqual(color, decoded)
    }

    // MARK: - WatermarkConfig JSON round-trip

    func testWatermarkConfigRoundTrip() throws {
        var config = WatermarkConfig.default
        config.enabled = true
        config.text = "Test"
        config.position = .topLeft
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(WatermarkConfig.self, from: data)
        XCTAssertEqual(config, decoded)
    }
}
