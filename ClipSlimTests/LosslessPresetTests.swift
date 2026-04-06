import XCTest
@testable import ClipSlim

final class LosslessPresetTests: XCTestCase {

    // MARK: - Preset Properties

    func testLosslessPresetHasQualityOne() {
        XCTAssertEqual(OptimizationPreset.lossless.quality, 1.0)
    }

    func testLosslessPresetHasMaxIntDimension() {
        XCTAssertEqual(OptimizationPreset.lossless.maxDimension, Int.max)
    }

    func testLosslessPresetStripsMetadata() {
        XCTAssertTrue(OptimizationPreset.lossless.stripMetadata)
    }

    func testLosslessPresetDoesNotAllowTransparencyLoss() {
        XCTAssertFalse(OptimizationPreset.lossless.allowTransparencyLoss)
    }

    func testLosslessPresetIsInAllCases() {
        XCTAssertTrue(OptimizationPreset.allCases.contains(.lossless))
    }

    func testLosslessPresetRawValue() {
        XCTAssertEqual(OptimizationPreset.lossless.rawValue, "Lossless")
    }

    // MARK: - Lossless Optimization

    func testLosslessPNGPreservesAlpha() async throws {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let context = CGContext(
            data: nil, width: 50, height: 50, bitsPerComponent: 8, bytesPerRow: 0,
            space: colorSpace, bitmapInfo: bitmapInfo.rawValue
        ) else {
            XCTFail("Failed to create context")
            return
        }

        context.clear(CGRect(x: 0, y: 0, width: 50, height: 50))
        context.setFillColor(red: 1, green: 0, blue: 0, alpha: 0.5)
        context.fillEllipse(in: CGRect(x: 5, y: 5, width: 40, height: 40))

        guard let image = context.makeImage() else {
            XCTFail("Failed to create image")
            return
        }

        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData as CFMutableData, "public.png" as CFString, 1, nil
        ) else {
            XCTFail("Failed to create destination")
            return
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            XCTFail("Failed to finalize")
            return
        }

        let pngData = mutableData as Data
        let config = ImageOptimizer.OptimizationConfig(
            quality: OptimizationPreset.lossless.quality,
            maxDimension: OptimizationPreset.lossless.maxDimension,
            stripMetadata: OptimizationPreset.lossless.stripMetadata,
            allowTransparencyLoss: OptimizationPreset.lossless.allowTransparencyLoss
        )

        let (_, result) = try await ImageOptimizer.shared.optimize(data: pngData, config: config)
        XCTAssertEqual(result.format, .png, "Lossless with alpha should stay PNG")
    }

    // MARK: - All Presets Coverage

    func testAllPresetsHaveConsistentProperties() {
        for preset in OptimizationPreset.allCases {
            XCTAssertGreaterThan(preset.quality, 0)
            XCTAssertLessThanOrEqual(preset.quality, 1.0)
            XCTAssertGreaterThan(preset.maxDimension, 0)
        }
    }
}
