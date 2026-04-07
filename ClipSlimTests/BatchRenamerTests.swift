import XCTest
@testable import ClipSlim

final class BatchRenamerTests: XCTestCase {

    private func makeContext(name: String = "photo", ext: String = "webp", seq: Int = 1) -> RenameContext {
        RenameContext(
            originalName: name,
            outputExtension: ext,
            date: Date(),
            sequenceNumber: seq,
            width: 1920,
            height: 1080,
            formatName: ext,
            presetName: "Web quality",
            savingsPercent: 42
        )
    }

    func testDefaultTemplate() {
        let ctx = makeContext()
        let result = BatchRenamer.rename(template: "{name}_optimized", context: ctx)
        XCTAssertEqual(result, "photo_optimized")
    }

    func testAllTokens() {
        let ctx = makeContext(seq: 5)
        let result = BatchRenamer.rename(
            template: "{name}_{date}_{time}_{n}_{width}x{height}_{format}_{preset}_{savings}pct",
            context: ctx
        )
        XCTAssertTrue(result.contains("photo_"))
        XCTAssertTrue(result.contains("_005_"))
        XCTAssertTrue(result.contains("1920x1080"))
        XCTAssertTrue(result.contains("_webp_"))
        XCTAssertTrue(result.contains("_Web quality_"))
        XCTAssertTrue(result.contains("42pct"))
    }

    func testUnknownTokenLeftAsLiteral() {
        let ctx = makeContext()
        let result = BatchRenamer.rename(template: "{name}_{bogus}", context: ctx)
        XCTAssertEqual(result, "photo_{bogus}")
    }

    func testNoTokensJustLiteral() {
        let ctx = makeContext()
        let result = BatchRenamer.rename(template: "fixed-name", context: ctx)
        XCTAssertEqual(result, "fixed-name")
    }

    func testUnclosedBrace() {
        let ctx = makeContext()
        let result = BatchRenamer.rename(template: "{name}_{broken", context: ctx)
        XCTAssertEqual(result, "photo_{broken")
    }

    func testPreviewProducesNonEmpty() {
        let preview = BatchRenamer.preview(template: "{name}_{date}")
        XCTAssertFalse(preview.isEmpty)
        XCTAssertTrue(preview.hasSuffix(".webp"))
    }

    func testSequenceNumberZeroPadded() {
        let ctx = makeContext(seq: 7)
        let result = BatchRenamer.rename(template: "{n}", context: ctx)
        XCTAssertEqual(result, "007")
    }

    func testEmptyTemplate() {
        let ctx = makeContext()
        let result = BatchRenamer.rename(template: "", context: ctx)
        XCTAssertEqual(result, "")
    }

    func testExtToken() {
        let ctx = makeContext(ext: "png")
        let result = BatchRenamer.rename(template: "{name}.{ext}", context: ctx)
        XCTAssertEqual(result, "photo.png")
    }

    func testSavingsToken() {
        let ctx = makeContext()
        let result = BatchRenamer.rename(template: "{name}_{savings}pct", context: ctx)
        XCTAssertEqual(result, "photo_42pct")
    }
}
