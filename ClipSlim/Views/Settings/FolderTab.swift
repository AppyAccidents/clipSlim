import SwiftUI

struct FolderTab: View {

    @Environment(AppViewModel.self) private var viewModel

    private var folderWatchBinding: Binding<Bool> {
        Binding(
            get: { viewModel.settings.folderWatchEnabled },
            set: { viewModel.setFolderWatchEnabled($0) }
        )
    }

    var body: some View {
        VibeSettingsPage {
            VibeSettingsCard(title: "Watched Folders", icon: "folder.badge.gearshape") {
                Toggle("Enable Folder Watching", isOn: folderWatchBinding)

                HStack {
                    Button("Add Folder…") { _ = viewModel.addWatchFolders() }
                        .buttonStyle(.bordered)
                    Spacer()
                    Text("\(viewModel.settings.watchedFolders.count) selected")
                        .font(VibeCheckTheme.Typography.caption)
                        .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                }

                ScrollView {
                    VStack(spacing: 0) {
                        if viewModel.settings.watchedFolders.isEmpty {
                            Text("No folders selected")
                                .font(VibeCheckTheme.Typography.caption)
                                .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(VibeCheckTheme.Spacing.md)
                        } else {
                            ForEach(viewModel.settings.watchedFolders) { folder in
                                HStack {
                                    Image(systemName: "folder")
                                        .foregroundColor(VibeCheckTheme.Colors.neonCyan)
                                    Text(folder.displayName)
                                        .lineLimit(1)
                                    Spacer()
                                    Button("Remove") {
                                        viewModel.removeWatchFolder(folder)
                                    }
                                    .buttonStyle(.borderless)
                                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                                }
                                .padding(.horizontal, VibeCheckTheme.Spacing.md)
                                .padding(.vertical, VibeCheckTheme.Spacing.sm)

                                if folder.id != viewModel.settings.watchedFolders.last?.id {
                                    VibeDivider()
                                }
                            }
                        }
                    }
                }
                .frame(height: 170)
                .background(VibeCheckTheme.Colors.backgroundCard)
                .cornerRadius(VibeCheckTheme.CornerRadius.sm)

                VibeHintText(text: "Optimized outputs land in an \"Optimized\" subfolder, so ClipSlim doesn't eat its own tail.")
            }

            VibeSettingsCard(title: "Info", icon: "info.circle") {
                Text("Supported formats: JPEG, PNG, TIFF, BMP, HEIC")
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.textSecondary)

                Text("PDF support: Coming soon")
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.textSecondary)

                Text("PDF page separation/stitching: Coming soon")
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.textSecondary)

                if viewModel.folderWatcher.isWatching {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(viewModel.folderWatcher.watchedPaths, id: \.self) { path in
                            HStack {
                                Circle()
                                    .fill(VibeCheckTheme.Colors.success)
                                    .frame(width: 8, height: 8)
                                Text(path)
                                    .font(VibeCheckTheme.Typography.caption)
                                    .foregroundColor(VibeCheckTheme.Colors.success)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                    }
                }
            }
        }
    }
}
