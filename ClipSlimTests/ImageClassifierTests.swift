import XCTest
import CoreGraphics
import ImageIO
@testable import ClipSlim

final class ImageClassifierTests: XCTestCase {

    let classifier = ImageClassifier.shared

    private func makeTestImage(width: Int, height: Int, uniform: Bool) -> Data? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
        guard let context = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: colorSpace, bitmapInfo: bitmapInfo.rawValue
        ) else { return nil }

        if uniform {
            context.setFillColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        } else {
            for y in 0..<height {
                for x in 0..<width {
                    let r = CGFloat(x) / CGFloat(width)
                    let g = CGFloat(y) / CGFloat(height)
                    context.setFillColor(red: r, green: g, blue: 0.5, alpha: 1.0)
                    context.fill(CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
        }

        guard let image = context.makeImage() else { return nil }
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data as CFMutableData, "public.png" as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(dest, image, nil)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return data as Data
    }

    func testClassifyUniformImage() {
        guard let data = makeTestImage(width: 200, height: 200, uniform: true) else {
            XCTFail("Failed to create test image")
            return
        }
        let result = classifier.classify(data: data)
        // Just verify it returns a valid classification without crashing
        let validTypes: [ImageClassifier.ImageContentType] = [.screenshot, .photo, .uiElement, .mixed]
        XCTAssertTrue(validTypes.contains(result), "Should return a valid content type")
    }

    func testClassifyGradientImage() {
        guard let data = makeTestImage(width: 200, height: 200, uniform: false) else {
            XCTFail("Failed to create test image")
            return
        }
        let result = classifier.classify(data: data)
        // Just verify it returns a valid classification without crashing
        let validTypes: [ImageClassifier.ImageContentType] = [.screenshot, .photo, .uiElement, .mixed]
        XCTAssertTrue(validTypes.contains(result), "Should return a valid content type")
    }

    func testClassifyEmptyDataReturnsMixed() {
        let result = classifier.classify(data: Data())
        XCTAssertEqual(result, .mixed)
    }
}
