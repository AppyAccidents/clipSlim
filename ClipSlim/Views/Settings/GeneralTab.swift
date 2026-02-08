import SwiftUI

struct GeneralTab: View {
    
    @Environment(AppViewModel.self) private var viewModel
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable Clipboard Watching", isOn: viewModel.settings.clipboardWatchEnabledBinding)
                    .onChange(of: viewModel.settings.clipboardWatchEnabled) { _, newValue in
                        if newValue {
                            viewModel.clipboardWatcher.start()
                        } else {
                            viewModel.clipboardWatcher.stop()
                        }
                    }
                
                Text("Automatically optimize images copied to the clipboard")
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
            } header: {
                Label("Clipboard", systemImage: "doc.on.clipboard")
            }
            
            Section {
                Toggle("Show Notifications", isOn: viewModel.settings.notificationsEnabledBinding)
                
                Text("Display a banner when an image is optimized")
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
            } header: {
                Label("Notifications", systemImage: "bell")
            }
            
            Section {
                HStack {
                    Text("Max Input Size")
                    Spacer()
                    Picker("", selection: viewModel.settings.maxFileSizeMBBinding) {
                        Text("10 MB").tag(10)
                        Text("25 MB").tag(25)
                        Text("50 MB").tag(50)
                        Text("100 MB").tag(100)
                    }
                    .frame(width: 120)
                }
                
                Text("Images larger than this will be skipped")
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
            } header: {
                Label("Safety", systemImage: "shield")
            }
            
            Section {
                Toggle("Launch at Login", isOn: viewModel.settings.launchAtLoginBinding)
                    .disabled(true)
                
                Text("Coming soon — requires a login item helper")
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
            } header: {
                Label("Startup", systemImage: "power")
            }
        }
        .formStyle(.grouped)
    }
}
