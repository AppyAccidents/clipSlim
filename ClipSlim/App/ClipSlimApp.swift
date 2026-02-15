import SwiftUI

@main
struct ClipSlimApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var viewModel: AppViewModel

    init() {
        let vm = AppViewModel()
        _viewModel = State(initialValue: vm)
        vm.startServices()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(viewModel)
        } label: {
            Image(systemName: viewModel.settings.menuBarIconStyle.sfSymbolName)
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
