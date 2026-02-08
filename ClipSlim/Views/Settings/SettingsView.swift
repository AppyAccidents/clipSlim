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
                    Label("Folder", systemImage: "folder")
                }
            
            AboutTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 480, height: 560)
    }
}
