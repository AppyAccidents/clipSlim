import SwiftUI

struct SettingsView: View {

    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        TabView {
            GeneralTab()
                .environment(viewModel)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            PresetsTab()
                .environment(viewModel)
                .tabItem {
                    Label("Presets", systemImage: "slider.horizontal.3")
                }

            FolderTab()
                .environment(viewModel)
                .tabItem {
                    Label("Folders", systemImage: "folder")
                }

            RulesTab()
                .environment(viewModel)
                .tabItem {
                    Label("Rules", systemImage: "line.3.horizontal.decrease.circle")
                }

            SupportTab()
                .environment(viewModel)
                .tabItem {
                    Label("Support", systemImage: "cup.and.saucer")
                }

            AboutTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 560, height: 620)
        .font(VibeCheckTheme.Typography.body)
        .tint(VibeCheckTheme.Colors.neonCyan)
        .padding(VibeCheckTheme.Spacing.sm)
        .background(VibeCheckTheme.Colors.background)
        .preferredColorScheme(.dark)
    }
}
