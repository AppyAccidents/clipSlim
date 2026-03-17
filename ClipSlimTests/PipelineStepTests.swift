import XCTest
@testable import ClipSlim

final class PipelineStepTests: XCTestCase {

    func testAllCasesCount() {
        XCTAssertEqual(PipelineStep.allCases.count, 4)
    }

    func testDefaultSettingsHasAllStepsEnabled() {
        let settings = AppSettings(defaults: UserDefaults(suiteName: "PipelineStepTests")!)
        let enabled = settings.enabledPipelineSteps
        XCTAssertEqual(enabled.count, PipelineStep.allCases.count)
    }

    func testToggleStepRemovesIt() {
        let defaults = UserDefaults(suiteName: "PipelineStepToggle")!
        defaults.removePersistentDomain(forName: "PipelineStepToggle")
        let settings = AppSettings(defaults: defaults)
        XCTAssertTrue(settings.isPipelineStepEnabled(.resize))
        settings.togglePipelineStep(.resize)
        XCTAssertFalse(settings.isPipelineStepEnabled(.resize))
    }

    func testToggleStepAddsItBack() {
        let defaults = UserDefaults(suiteName: "PipelineStepToggle2")!
        defaults.removePersistentDomain(forName: "PipelineStepToggle2")
        let settings = AppSettings(defaults: defaults)
        settings.togglePipelineStep(.compress)
        XCTAssertFalse(settings.isPipelineStepEnabled(.compress))
        settings.togglePipelineStep(.compress)
        XCTAssertTrue(settings.isPipelineStepEnabled(.compress))
    }

    func testDisplayNames() {
        XCTAssertEqual(PipelineStep.resize.displayName, "Resize")
        XCTAssertEqual(PipelineStep.stripMetadata.displayName, "Strip Metadata")
        XCTAssertEqual(PipelineStep.compress.displayName, "Compress")
        XCTAssertEqual(PipelineStep.convertFormat.displayName, "Convert Format")
    }
}
