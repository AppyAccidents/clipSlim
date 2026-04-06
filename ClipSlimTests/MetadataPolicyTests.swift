import XCTest
@testable import ClipSlim

final class MetadataPolicyTests: XCTestCase {

    func testStripAllRemovesEverything() {
        let policy = MetadataPolicy.stripAll
        XCTAssertTrue(policy.shouldStripGPS)
        XCTAssertTrue(policy.shouldStripCameraInfo)
        XCTAssertFalse(policy.shouldKeepCopyright)
        XCTAssertFalse(policy.shouldKeepAuthor)
        XCTAssertTrue(policy.effectiveStripMetadata)
    }

    func testKeepAllPreservesEverything() {
        let policy = MetadataPolicy.keepAll
        XCTAssertFalse(policy.shouldStripGPS)
        XCTAssertFalse(policy.shouldStripCameraInfo)
        XCTAssertTrue(policy.shouldKeepCopyright)
        XCTAssertTrue(policy.shouldKeepAuthor)
        XCTAssertFalse(policy.effectiveStripMetadata)
    }

    func testSelectiveKeepsCopyrightStripsGPS() {
        let policy = MetadataPolicy(
            mode: .selective,
            keepCopyright: true,
            keepAuthor: false,
            stripGPS: true,
            stripCameraInfo: true
        )
        XCTAssertTrue(policy.shouldStripGPS)
        XCTAssertTrue(policy.shouldStripCameraInfo)
        XCTAssertTrue(policy.shouldKeepCopyright)
        XCTAssertFalse(policy.shouldKeepAuthor)
        XCTAssertFalse(policy.effectiveStripMetadata)
    }

    func testLegacyMigrationStripTrue() {
        let policy = MetadataPolicy.fromLegacy(stripMetadata: true)
        XCTAssertEqual(policy.mode, .stripAll)
    }

    func testLegacyMigrationStripFalse() {
        let policy = MetadataPolicy.fromLegacy(stripMetadata: false)
        XCTAssertEqual(policy.mode, .keepAll)
    }

    func testCodableRoundTrip() throws {
        let policy = MetadataPolicy(
            mode: .selective,
            keepCopyright: true,
            keepAuthor: false,
            stripGPS: true,
            stripCameraInfo: false
        )
        let encoded = try JSONEncoder().encode(policy)
        let decoded = try JSONDecoder().decode(MetadataPolicy.self, from: encoded)
        XCTAssertEqual(decoded.mode, policy.mode)
        XCTAssertEqual(decoded.keepCopyright, policy.keepCopyright)
        XCTAssertEqual(decoded.keepAuthor, policy.keepAuthor)
        XCTAssertEqual(decoded.stripGPS, policy.stripGPS)
        XCTAssertEqual(decoded.stripCameraInfo, policy.stripCameraInfo)
    }
}
