import XCTest
import CoreGraphics
import ImageIO
@testable import ClipSlim

final class QualityScorerTests: XCTestCase {

    let scorer = QualityScorer.shared

    private func makeSolidPNG(width: Int, height: Int, red: CGFloat, green: CGFloat, blue: CGFloat) -> Data? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { return nil }

        context.setFillColor(red: red, green: green, blue: blue, alpha: 1.0)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        guard let image = context.makeImage() else { return nil }
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data as CFMutableData, "public.png" as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(dest, image, nil)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return data as Data
    }

    func testIdenticalImagesReturnSSIMNearOne() {
        guard let data = makeSolidPNG(width: 100, height: 100, red: 0.5, green: 0.5, blue: 0.5) else {
            XCTFail("Failed to create test image")
            return
        }
        let ssim = scorer.computeSSIM(original: data, optimized: data)
        XCTAssertGreaterThan(ssim, 0.99, "Identical images should have SSIM > 0.99, got \(ssim)")
    }

    func testVeryDifferentImagesReturnLowSSIM() {
        guard let white = makeSolidPNG(width: 100, height: 100, red: 1.0, green: 1.0, blue: 1.0),
              let black = makeSolidPNG(width: 100, height: 100, red: 0.0, green: 0.0, blue: 0.0) else {
            XCTFail("Failed to create test images")
            return
        }
        let ssim = scorer.computeSSIM(original: white, optimized: black)
        XCTAssertLessThan(ssim, 0.2, "White vs black should have low SSIM, got \(ssim)")
    }

    func testInvalidDataReturnsOne() {
        let ssim = scorer.computeSSIM(original: Data(), optimized: Data())
        XCTAssertEqual(ssim, 1.0, "Invalid data should return 1.0")
    }
}
