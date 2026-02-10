import SwiftUI

struct GeneralTab: View {

    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        VibeSettingsPage {
            VibeSettingsCard(title: "Clipboard", icon: "doc.on.clipboard") {
                Toggle("Enable Clipboard Watching", isOn: viewModel.settings.clipboardWatchEnabledBinding)
                    .onChange(of: viewModel.settings.clipboardWatchEnabled) { _, _ in
                        viewModel.refreshPauseState()
                    }
                VibeHintText(text: "Automatically optimize images copied to the clipboard")
            }

            VibeSettingsCard(title: "Output Format", icon: "arrow.triangle.2.circlepath") {
                Picker("Preferred Output Format", selection: Binding(
                    get: { viewModel.settings.preferredOutputFormat },
                    set: { viewModel.settings.preferredOutputFormat = $0 }
                )) {
                    Text("JPEG").tag(ImageFormat.jpeg)
                    Text("PNG").tag(ImageFormat.png)
                }
                .pickerStyle(.segmented)

                VibeHintText(text: "If JPEG is preferred and input has transparency, ClipSlim forces PNG to preserve alpha.")
            }

            VibeSettingsCard(title: "Appearance", icon: "paintbrush") {
                HStack {
                    Text("Menu Bar Icon")
                        .foregroundColor(VibeCheckTheme.Colors.textPrimary)
                    Spacer()
                    Picker("", selection: viewModel.settings.menuBarIconStyleBinding) {
                        ForEach(MenuBarIconStyle.allCases, id: \.self) { style in
                            HStack(spacing: VibeCheckTheme.Spacing.xs) {
                                Image(systemName: style.sfSymbolName)
                                Text(style.title)
                            }
                            .tag(style)
                        }
                    }
                    .frame(width: 160)
                }
                VibeHintText(text: "Choose the icon shown in the menu bar. Change takes effect immediately.")
            }

            VibeSettingsCard(title: "Pause & Focus", icon: "moon.zzz") {
                Toggle("Pause folder watcher while paused", isOn: viewModel.settings.pauseFolderWatcherBinding)
                Toggle("Focus mode", isOn: viewModel.settings.focusModeEnabledBinding)
                    .onChange(of: viewModel.settings.focusModeEnabled) { _, _ in
                        viewModel.refreshPauseState()
                    }

                TextField("Focus bundle IDs (comma-separated)", text: Binding(
                    get: { viewModel.settings.focusBundleIDsCSV },
                    set: { viewModel.settings.focusBundleIDsCSV = $0 }
                ))
                .textFieldStyle(.roundedBorder)

                TextField("Always ignore apps (comma-separated)", text: Binding(
                    get: { viewModel.settings.excludedBundleIDsCSV },
                    set: { viewModel.settings.excludedBundleIDsCSV = $0 }
                ))
                .textFieldStyle(.roundedBorder)

                VibeHintText(text: "Focus mode pauses clipboard optimization when frontmost app matches configured bundle IDs.")
            }

            VibeSettingsCard(title: "Notifications", icon: "bell") {
                Toggle("Show Notifications", isOn: viewModel.settings.notificationsEnabledBinding)
            }

            VibeSettingsCard(title: "Safety", icon: "shield") {
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
                VibeHintText(text: "Images larger than this are skipped")
            }

            VibeSettingsCard(title: "Save to Disk", icon: "square.and.arrow.down") {
                Toggle("Save originals and optimized files to disk", isOn: viewModel.settings.saveToDiskBinding)
                if viewModel.settings.saveToDisk {
                    HStack {
                        Text(viewModel.settings.saveFolderPath.isEmpty ? "~/Pictures/ClipSlim (default)" : viewModel.settings.saveFolderPath)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button("Choose…") { selectSaveFolder() }
                    }
                }
            }

            VibeSettingsCard(title: "Onboarding", icon: "sparkles") {
                Button("Run onboarding again") {
                    viewModel.runOnboardingAgain()
                }
                .buttonStyle(.bordered)
                VibeHintText(text: "Use onboarding to reset default format, optimization intensity, and watched folders.")
            }
        }
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
