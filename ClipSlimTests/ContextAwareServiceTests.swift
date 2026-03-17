import XCTest
@testable import ClipSlim

@MainActor
final class ContextAwareServiceTests: XCTestCase {

    func testDefaultMappingsLoaded() {
        let service = ContextAwareService()
        XCTAssertFalse(service.mappings.isEmpty)
    }

    func testSuggestedPresetForKnownApp() {
        let service = ContextAwareService()
        let suggestion = service.suggestedPreset(for: "com.tinyspeck.slackmacgap")
        XCTAssertNotNil(suggestion)
        XCTAssertEqual(suggestion?.preset, .compressed)
    }

    func testSuggestedPresetForUnknownAppReturnsNil() {
        let service = ContextAwareService()
        let suggestion = service.suggestedPreset(for: "com.unknown.app")
        XCTAssertNil(suggestion)
    }

    func testRecordAcceptIncrements() {
        let defaults = UserDefaults(suiteName: "ContextAwareTest")!
        defaults.removePersistentDomain(forName: "ContextAwareTest")
        let settings = AppSettings(defaults: defaults)
        let service = ContextAwareService()
        service.loadMappings(from: nil) // loads defaults

        let bundleID = "com.tinyspeck.slackmacgap"
        service.recordAccept(for: bundleID, settings: settings)
        let mapping = service.mappings.first { $0.bundleID == bundleID }
        XCTAssertEqual(mapping?.acceptCount, 1)
    }

    func testAutoApplyAfterFiveAccepts() {
        let defaults = UserDefaults(suiteName: "ContextAwareAutoApply")!
        defaults.removePersistentDomain(forName: "ContextAwareAutoApply")
        let settings = AppSettings(defaults: defaults)
        let service = ContextAwareService()
        service.loadMappings(from: nil)

        let bundleID = "com.tinyspeck.slackmacgap"
        for _ in 0..<5 {
            service.recordAccept(for: bundleID, settings: settings)
        }
        let mapping = service.mappings.first { $0.bundleID == bundleID }
        XCTAssertTrue(mapping?.autoApply ?? false)
    }
}
