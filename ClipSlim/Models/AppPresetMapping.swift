import Foundation

struct AppPresetMapping: Codable, Identifiable {
    let id: UUID
    var bundleID: String
    var appName: String
    var preset: String  // OptimizationPreset rawValue
    var acceptCount: Int
    var dismissCount: Int
    var autoApply: Bool

    init(
        id: UUID = UUID(),
        bundleID: String,
        appName: String,
        preset: String = "Web quality",
        acceptCount: Int = 0,
        dismissCount: Int = 0,
        autoApply: Bool = false
    ) {
        self.id = id
        self.bundleID = bundleID
        self.appName = appName
        self.preset = preset
        self.acceptCount = acceptCount
        self.dismissCount = dismissCount
        self.autoApply = autoApply
    }

    static let defaults: [AppPresetMapping] = [
        AppPresetMapping(bundleID: "com.tinyspeck.slackmacgap", appName: "Slack", preset: "Compressed"),
        AppPresetMapping(bundleID: "com.figma.Desktop", appName: "Figma", preset: "High quality"),
        AppPresetMapping(bundleID: "com.apple.mail", appName: "Mail", preset: "Web quality"),
        AppPresetMapping(bundleID: "com.apple.Safari", appName: "Safari", preset: "Web quality"),
    ]
}
