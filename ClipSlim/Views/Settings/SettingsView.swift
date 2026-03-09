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

            PDFTab()
                .environment(viewModel)
                .tabItem {
                    Label("PDF", systemImage: "doc.richtext")
                }

            SupportTab()
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
        .tint(Color(hex: "FB8A10"))
        .padding(VibeCheckTheme.Spacing.sm)
        .background(VibeCheckTheme.Colors.background)
        .preferredColorScheme(.dark)
    }
}
