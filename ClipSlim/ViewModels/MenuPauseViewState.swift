import Foundation

struct MenuPauseViewState: Equatable {
    let isPaused: Bool

    var statusText: String {
        isPaused ? "Paused" : "Active"
    }

    var canPause: Bool {
        !isPaused
    }

    var canResume: Bool {
        isPaused
    }
}
