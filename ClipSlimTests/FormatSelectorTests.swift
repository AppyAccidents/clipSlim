import XCTest
@testable import ClipSlim

final class FormatSelectorTests: XCTestCase {

    let selector = FormatSelector.shared

    func testPhotoNoAlphaReturnsJPEG() {
        let config = FormatSelector.FormatSelectorConfig(smartFormatEnabled: true, webpPreferred: false)
        let result = selector.recommendFormat(classification: .photo, hasAlpha: false, config: config)
        XCTAssertEqual(result, .jpeg)
    }

    func testPhotoNoAlphaWebPPreferredReturnsWebP() {
        let config = FormatSelector.FormatSelectorConfig(smartFormatEnabled: true, webpPreferred: true)
        let result = selector.recommendFormat(classification: .photo, hasAlpha: false, config: config)
        XCTAssertEqual(result, .webp)
    }

    func testScreenshotReturnsPNG() {
        let config = FormatSelector.FormatSelectorConfig(smartFormatEnabled: true, webpPreferred: false)
        let result = selector.recommendFormat(classification: .screenshot, hasAlpha: false, config: config)
        XCTAssertEqual(result, .png)
    }

    func testUIElementReturnsPNG() {
        let config = FormatSelector.FormatSelectorConfig(smartFormatEnabled: true, webpPreferred: true)
        let result = selector.recommendFormat(classification: .uiElement, hasAlpha: false, config: config)
        XCTAssertEqual(result, .png)
    }

    func testPhotoWithAlphaReturnsPNG() {
        let config = FormatSelector.FormatSelectorConfig(smartFormatEnabled: true, webpPreferred: false)
        let result = selector.recommendFormat(classification: .photo, hasAlpha: true, config: config)
        XCTAssertEqual(result, .png)
    }

    func testDisabledSmartFormatReturnsJPEG() {
        let config = FormatSelector.FormatSelectorConfig(smartFormatEnabled: false, webpPreferred: true)
        let result = selector.recommendFormat(classification: .screenshot, hasAlpha: false, config: config)
        XCTAssertEqual(result, .jpeg)
    }
}
