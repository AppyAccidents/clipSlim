import XCTest
@testable import ClipSlim

final class MenuViewStateTests: XCTestCase {
    func testMenuPauseStateActive() {
        let state = MenuPauseViewState(isPaused: false)

        XCTAssertEqual(state.statusText, "Active")
        XCTAssertTrue(state.canPause)
        XCTAssertFalse(state.canResume)
    }

    func testMenuPauseStatePaused() {
        let state = MenuPauseViewState(isPaused: true)

        XCTAssertEqual(state.statusText, "Paused")
        XCTAssertFalse(state.canPause)
        XCTAssertTrue(state.canResume)
    }
}
