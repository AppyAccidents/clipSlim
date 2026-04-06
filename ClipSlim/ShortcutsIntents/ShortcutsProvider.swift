import AppIntents

struct ClipSlimShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OptimizeImageIntent(),
            phrases: [
                "Optimize image with \(.applicationName)",
                "Compress image with \(.applicationName)",
                "Slim image with \(.applicationName)"
            ],
            shortTitle: "Optimize Image",
            systemImageName: "scissors"
        )
    }
}
