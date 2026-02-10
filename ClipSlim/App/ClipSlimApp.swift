import SwiftUI

@main
struct ClipSlimApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var viewModel = AppViewModel()
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(viewModel)
        } label: {
            Image(systemName: "scissors")
                .font(.system(size: 13, weight: .semibold))
                .accessibilityLabel("ClipSlim")
        }
        .menuBarExtraStyle(.window)
        
        Settings {
            SettingsView()
                .environment(viewModel)
        }
        
        Window("Debug Log", id: "debug-log") {
            DebugLogView()
                .environment(viewModel)
        }
        .defaultSize(width: 600, height: 400)
    }
}
