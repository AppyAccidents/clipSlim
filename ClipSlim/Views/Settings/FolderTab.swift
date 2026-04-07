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

            FolderRulesSection()
                .environment(viewModel)

            VibeSettingsCard(title: "Output Naming", icon: "textformat") {
                VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.sm) {
                    Text("Rename Template")
                        .font(VibeCheckTheme.Typography.body)
                        .foregroundColor(VibeCheckTheme.Colors.textPrimary)

                    TextField("Template", text: viewModel.settings.renameTemplateBinding)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))

                    // Live preview
                    HStack(spacing: VibeCheckTheme.Spacing.xs) {
                        Text("Preview:")
                            .font(VibeCheckTheme.Typography.caption)
                            .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                        Text(BatchRenamer.preview(template: viewModel.settings.renameTemplate))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(VibeCheckTheme.Colors.neonCyan)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    // Preset buttons
                    HStack(spacing: VibeCheckTheme.Spacing.xs) {
                        renamePresetButton("Default", template: "{name}_optimized")
                        renamePresetButton("Dated", template: "{name}_{date}_{time}")
                        renamePresetButton("Full", template: "{name}_{date}_{n}_{width}x{height}")
                        Spacer()
                    }

                    VibeHintText(text: "Tokens: {name} {ext} {date} {time} {n} {width} {height} {format} {preset} {savings}. Extension is added automatically.")
                }
            }

            VibeSettingsCard(title: "Info", icon: "info.circle") {
                Text("Supported formats: JPEG, PNG, TIFF, BMP, HEIC")
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

    private func renamePresetButton(_ label: String, template: String) -> some View {
        let isSelected = viewModel.settings.renameTemplate == template
        return Button {
            viewModel.settings.renameTemplate = template
        } label: {
            Text(label)
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(isSelected ? .white : VibeCheckTheme.Colors.textSecondary)
                .padding(.horizontal, VibeCheckTheme.Spacing.sm)
                .padding(.vertical, VibeCheckTheme.Spacing.xs)
                .background(isSelected ? VibeCheckTheme.Colors.neonOrange : VibeCheckTheme.Colors.surface)
                .cornerRadius(VibeCheckTheme.CornerRadius.sm)
        }
        .buttonStyle(.plain)
    }
}
