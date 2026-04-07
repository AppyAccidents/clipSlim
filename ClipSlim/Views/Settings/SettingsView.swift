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

            AppMappingsTab()
                .environment(viewModel)
                .tabItem {
                    Label("App Rules", systemImage: "app.badge")
                }

            PresetsTab()
                .environment(viewModel)
                .tabItem {
                    Label("Presets", systemImage: "slider.horizontal.3")
                }

            StatsTab()
                .environment(viewModel)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
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

            VideoTab()
                .environment(viewModel)
                .tabItem {
                    Label("Video", systemImage: "film")
                }

            WatermarkTab()
                .environment(viewModel)
                .tabItem {
                    Label("Watermark", systemImage: "drop.halffull")
                }

            SupportTab()
                .environment(viewModel)
                .tabItem {
                    Label("Support", systemImage: "heart.fill")
                }

            AboutTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 560, height: 680)
        .font(VibeCheckTheme.Typography.body)
        .tint(VibeCheckTheme.Colors.neonOrange)
        .padding(VibeCheckTheme.Spacing.sm)
        .background(VibeCheckTheme.Colors.background)
        .preferredColorScheme(.dark)
    }
}
