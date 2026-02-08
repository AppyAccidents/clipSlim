import SwiftUI

struct FolderTab: View {
    
    @Environment(AppViewModel.self) private var viewModel
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable Folder Watching", isOn: viewModel.settings.folderWatchEnabledBinding)
                    .onChange(of: viewModel.settings.folderWatchEnabled) { _, newValue in
                        if newValue {
                            viewModel.toggleFolderWatch()
                            viewModel.settings.folderWatchEnabled = true
                        } else {
                            viewModel.folderWatcher.stop()
                        }
                    }
                
                HStack {
                    VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.xs) {
                        Text("Watched Folder")
                            .font(VibeCheckTheme.Typography.body)
                        
                        if viewModel.settings.watchedFolderPath.isEmpty {
                            Text("No folder selected")
                                .font(VibeCheckTheme.Typography.caption)
                                .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                        } else {
                            Text(viewModel.settings.watchedFolderPath)
                                .font(VibeCheckTheme.Typography.caption)
                                .foregroundColor(VibeCheckTheme.Colors.neonCyan)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                    
                    Spacer()
                    
                    Button("Choose…") {
                        viewModel.selectWatchFolder()
                    }
                }
                
                Text("New images dropped into this folder will be optimized automatically. Optimized files are saved as \"filename-optimized.ext\" — originals are never modified.")
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
            } header: {
                Label("Folder Watcher", systemImage: "folder.badge.gearshape")
            }
            
            Section {
                VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.sm) {
                    Text("Supported formats:")
                        .font(VibeCheckTheme.Typography.caption)
                        .foregroundColor(VibeCheckTheme.Colors.textSecondary)
                    
                    Text("JPEG, PNG, TIFF, BMP, HEIC")
                        .font(VibeCheckTheme.Typography.caption)
                        .foregroundColor(VibeCheckTheme.Colors.neonCyan)
                }
                
                VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.sm) {
                    Text("Skipped files:")
                        .font(VibeCheckTheme.Typography.caption)
                        .foregroundColor(VibeCheckTheme.Colors.textSecondary)
                    
                    Text("Files containing \"-optimized\" in their name, files that existed before watching started")
                        .font(VibeCheckTheme.Typography.caption)
                        .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                }
            } header: {
                Label("Info", systemImage: "info.circle")
            }
            
            if viewModel.folderWatcher.isWatching {
                Section {
                    HStack {
                        Circle()
                            .fill(VibeCheckTheme.Colors.success)
                            .frame(width: 8, height: 8)
                        Text("Watching: \(viewModel.folderWatcher.watchedPath)")
                            .font(VibeCheckTheme.Typography.caption)
                            .foregroundColor(VibeCheckTheme.Colors.success)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                } header: {
                    Label("Status", systemImage: "antenna.radiowaves.left.and.right")
                }
            }
        }
        .formStyle(.grouped)
    }
}
