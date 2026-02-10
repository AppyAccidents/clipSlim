import XCTest
@testable import ClipSlim

final class ImageOptimizerTests: XCTestCase {
    
    let optimizer = ImageOptimizer.shared
    
    // MARK: - Helper
    
    /// Creates a minimal valid PNG data (1x1 red pixel)
    private func makeTestPNG(
        width: Int = 100,
        height: Int = 100,
        hasAlpha: Bool = false,
        useTransparentContent: Bool = true
    ) -> Data? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo: CGBitmapInfo = hasAlpha
            ? CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
            : CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return nil }
        
        if hasAlpha && useTransparentContent {
            context.clear(CGRect(x: 0, y: 0, width: width, height: height))
            context.setFillColor(red: 1.0, green: 0.4, blue: 0.1, alpha: 0.5)
            context.fillEllipse(in: CGRect(x: 10, y: 10, width: width - 20, height: height - 20))
        } else {
            context.setFillColor(red: 0.2, green: 0.6, blue: 0.8, alpha: 1.0)
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            context.setFillColor(red: 1.0, green: 0.4, blue: 0.1, alpha: 1.0)
            context.fillEllipse(in: CGRect(x: 10, y: 10, width: width - 20, height: height - 20))
        }
        
        guard let image = context.makeImage() else { return nil }
        
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData as CFMutableData,
            "public.png" as CFString,
            1,
            nil
        ) else { return nil }
        
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        
        return mutableData as Data
    }
    
    // MARK: - Tests
    
    func testOptimizeValidPNG() async throws {
        guard let pngData = makeTestPNG() else {
            XCTFail("Failed to create test PNG")
            return
        }
        
        let config = ImageOptimizer.OptimizationConfig(quality: 0.75, maxDimension: 1920)
        let (optimizedData, result) = try await optimizer.optimize(data: pngData, config: config)
        
        XCTAssertFalse(optimizedData.isEmpty, "Optimized data should not be empty")
        XCTAssertEqual(result.format, .jpeg, "Non-alpha PNG should produce JPEG output")
        XCTAssertEqual(result.originalDimensions.width, 100)
        XCTAssertEqual(result.originalDimensions.height, 100)
        XCTAssertGreaterThan(result.duration, 0)
    }
    
    func testTransparencyPreservation() async throws {
        guard let pngData = makeTestPNG(hasAlpha: true) else {
            XCTFail("Failed to create test PNG with alpha")
            return
        }
        
        let config = ImageOptimizer.OptimizationConfig(quality: 0.75, maxDimension: 1920, stripMetadata: true, allowTransparencyLoss: false)
        let (_, result) = try await optimizer.optimize(data: pngData, config: config)
        
        XCTAssertEqual(result.format, .png, "Alpha PNG with allowTransparencyLoss=false should stay PNG")
    }
    
    func testTransparencyLossAllowed() async throws {
        guard let pngData = makeTestPNG(hasAlpha: true) else {
            XCTFail("Failed to create test PNG with alpha")
            return
        }
        
        let config = ImageOptimizer.OptimizationConfig(quality: 0.75, maxDimension: 1920, stripMetadata: true, allowTransparencyLoss: true)
        let (_, result) = try await optimizer.optimize(data: pngData, config: config)
        
        XCTAssertEqual(result.format, .jpeg, "Alpha PNG with allowTransparencyLoss=true should become JPEG")
    }

    func testOpaqueAlphaChannelUsesJPEGWhenTransparencyMustBePreserved() async throws {
        guard let pngData = makeTestPNG(hasAlpha: true, useTransparentContent: false) else {
            XCTFail("Failed to create opaque PNG with alpha channel")
            return
        }

        let config = ImageOptimizer.OptimizationConfig(quality: 0.75, maxDimension: 1920, stripMetadata: true, allowTransparencyLoss: false)
        let (_, result) = try await optimizer.optimize(data: pngData, config: config)

        XCTAssertEqual(result.format, .jpeg, "Opaque image with alpha channel should still use JPEG")
    }
    
    func testResizeDownscale() async throws {
        guard let pngData = makeTestPNG(width: 3000, height: 2000) else {
            XCTFail("Failed to create large test PNG")
            return
        }
        
        let config = ImageOptimizer.OptimizationConfig(quality: 0.75, maxDimension: 1920)
        let (_, result) = try await optimizer.optimize(data: pngData, config: config)
        
        XCTAssertLessThanOrEqual(result.optimizedDimensions.width, 1920)
        XCTAssertLessThanOrEqual(result.optimizedDimensions.height, 1920)
    }
    
    func testNoResizeWhenSmall() async throws {
        guard let pngData = makeTestPNG(width: 200, height: 150) else {
            XCTFail("Failed to create small test PNG")
            return
        }
        
        let config = ImageOptimizer.OptimizationConfig(quality: 0.75, maxDimension: 1920)
        let (_, result) = try await optimizer.optimize(data: pngData, config: config)
        
        XCTAssertEqual(result.optimizedDimensions.width, 200)
        XCTAssertEqual(result.optimizedDimensions.height, 150)
    }

    func testExactResizeToTargetDimensions() async throws {
        guard let pngData = makeTestPNG(width: 640, height: 360) else {
            XCTFail("Failed to create source PNG")
            return
        }

        let config = ImageOptimizer.OptimizationConfig(
            quality: 0.75,
            maxDimension: 1920,
            targetDimensions: (width: 128, height: 128)
        )
        let (_, result) = try await optimizer.optimize(data: pngData, config: config)

        XCTAssertEqual(result.optimizedDimensions.width, 128)
        XCTAssertEqual(result.optimizedDimensions.height, 128)
    }
    
    func testEmptyDataThrows() async {
        let config = ImageOptimizer.OptimizationConfig()
        do {
            _ = try await optimizer.optimize(data: Data(), config: config)
            XCTFail("Should have thrown for empty data")
        } catch {
            XCTAssertTrue(error is OptimizationError)
        }
    }
    
    func testInvalidDataThrows() async {
        let config = ImageOptimizer.OptimizationConfig()
        let garbage = Data("not an image".utf8)
        do {
            _ = try await optimizer.optimize(data: garbage, config: config)
            XCTFail("Should have thrown for invalid data")
        } catch {
            XCTAssertTrue(error is OptimizationError)
        }
    }
    
    func testSavingsCalculation() {
        let result = OptimizationResult(
            originalSize: 1000,
            optimizedSize: 600,
            format: .jpeg,
            duration: 0.1,
            originalDimensions: (100, 100),
            optimizedDimensions: (100, 100)
        )
        
        XCTAssertEqual(result.savingsPercentage, 40.0, accuracy: 0.01)
        XCTAssertEqual(result.savingsBytes, 400)
    }
}
