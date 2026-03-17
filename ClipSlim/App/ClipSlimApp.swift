import SwiftUI
import SwiftData

@main
struct ClipSlimApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var viewModel: AppViewModel

    let modelContainer: ModelContainer

    init() {
        let vm = AppViewModel()
        _viewModel = State(initialValue: vm)
        modelContainer = PersistenceController.shared.container
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
                .modelContainer(modelContainer)
        }

        Window("Debug Log", id: "debug-log") {
            DebugLogView()
                .environment(viewModel)
        }
        .defaultSize(width: 600, height: 400)

        Window("Clipboard History", id: "clipboard-history") {
            ClipboardHistoryView()
                .modelContainer(modelContainer)
        }
        .defaultSize(width: 480, height: 400)

    }
}
