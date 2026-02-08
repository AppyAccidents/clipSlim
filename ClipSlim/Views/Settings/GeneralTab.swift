import SwiftUI
import AppKit

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
                Toggle("Save Originals & Optimized to Disk", isOn: viewModel.settings.saveToDiskBinding)
                
                if viewModel.settings.saveToDisk {
                    HStack {
                        VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.xs) {
                            Text("Save Folder")
                                .font(VibeCheckTheme.Typography.body)
                            
                            if viewModel.settings.saveFolderPath.isEmpty {
                                Text("~/Pictures/ClipSlim (default)")
                                    .font(VibeCheckTheme.Typography.caption)
                                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                            } else {
                                Text(viewModel.settings.saveFolderPath)
                                    .font(VibeCheckTheme.Typography.caption)
                                    .foregroundColor(VibeCheckTheme.Colors.neonCyan)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                        
                        Spacer()
                        
                        Button("Choose…") {
                            selectSaveFolder()
                        }
                    }
                }
                
                Text("Saves both original and optimized images in separate Originals/ and Optimized/ subfolders")
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
            } header: {
                Label("Save to Disk", systemImage: "square.and.arrow.down")
            }
            
            Section {
                Picker("Preferred Output Format", selection: Binding(
                    get: { viewModel.settings.preferredOutputFormatRaw },
                    set: { viewModel.settings.preferredOutputFormatRaw = $0 }
                )) {
                    Text("Auto").tag("")
                    Text("JPEG").tag(ImageFormat.jpeg.rawValue)
                    Text("PNG").tag(ImageFormat.png.rawValue)
                }
                
                Text("Auto: HEIC/TIFF → PNG, others → JPEG (unless transparent). Override to force a specific format.")
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
            } header: {
                Label("Format Conversion", systemImage: "arrow.triangle.2.circlepath")
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
    
    private func selectSaveFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose a folder to save original and optimized images"
        panel.prompt = "Select Folder"
        
        if panel.runModal() == .OK, let url = panel.url {
            viewModel.settings.saveFolderPath = url.path
        }
    }
}
