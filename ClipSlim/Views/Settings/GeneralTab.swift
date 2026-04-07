import SwiftUI

struct GeneralTab: View {

    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        VibeSettingsPage {
            VibeSettingsCard(title: "Clipboard", icon: "doc.on.clipboard") {
                Toggle("Enable Clipboard Watching", isOn: viewModel.settings.clipboardWatchEnabledBinding)
                    .onChange(of: viewModel.settings.clipboardWatchEnabled) { _, _ in
                        viewModel.reconcileWatcherState()
                    }
                VibeHintText(text: "Automatically slim images copied to the clipboard, no manual button mashing required.")
            }

            VibeSettingsCard(title: "Output Format", icon: "arrow.triangle.2.circlepath") {
                Picker("Preferred Output Format", selection: Binding(
                    get: { viewModel.settings.preferredOutputFormat },
                    set: { viewModel.settings.preferredOutputFormat = $0 }
                )) {
                    Text("JPEG").tag(ImageFormat.jpeg)
                    Text("PNG").tag(ImageFormat.png)
                    Text("WebP").tag(ImageFormat.webp)
                }
                .pickerStyle(.segmented)

                Toggle("Smart Format Detection", isOn: viewModel.settings.smartFormatEnabledBinding)
                VibeHintText(text: "When enabled, ClipSlim auto-selects the best format based on image content (screenshots → PNG, photos → JPEG/WebP).")
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
                Toggle("Pause folder watcher.", isOn: viewModel.settings.pauseFolderWatcherBinding)
                    .onChange(of: viewModel.settings.pauseFolderWatcher) { _, _ in
                        viewModel.reconcileWatcherState()
                    }
                Toggle("Focus mode", isOn: viewModel.settings.focusModeEnabledBinding)
                    .onChange(of: viewModel.settings.focusModeEnabled) { _, _ in
                        viewModel.reconcileWatcherState()
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

            VibeSettingsCard(title: "Global Shortcuts", icon: "keyboard") {
                ShortcutsSettingsContent()
                    .environment(viewModel)
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
                    Picker("Save destination", selection: viewModel.settings.saveDestinationModeBinding) {
                        ForEach(SaveDestinationMode.allCases, id: \.self) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    VibeHintText(text: "Clipboard images in same-folder mode fall back to your custom folder.")

                    if viewModel.settings.saveDestinationMode == .customFolder {
                        HStack {
                            Text(viewModel.settings.saveFolderPath.isEmpty ? "No custom folder selected" : viewModel.settings.saveFolderPath)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            Button("Choose…") { selectSaveFolder() }
                        }
                    } else {
                        HStack {
                            Text(viewModel.settings.saveFolderPath.isEmpty ? "No fallback custom folder selected" : "Fallback folder: \(viewModel.settings.saveFolderPath)")
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            Button("Set fallback…") { selectSaveFolder() }
                        }
                    }
                }
            }

            VibeSettingsCard(title: "Advanced", icon: "wrench.and.screwdriver") {
                Toggle("Developer Mode", isOn: viewModel.settings.developerModeEnabledBinding)
                VibeHintText(text: "Show detailed optimization info in the overlay: timing, format reasoning, SSIM score, content classification.")

                Toggle("Quality Guard", isOn: viewModel.settings.qualityGuardEnabledBinding)
                if viewModel.settings.qualityGuardEnabled {
                    HStack {
                        Text("Threshold")
                        Spacer()
                        Text("\(Int(viewModel.settings.qualityGuardThreshold * 100))%")
                            .font(VibeCheckTheme.Typography.monospacedBold)
                            .foregroundColor(VibeCheckTheme.Colors.neonCyan)
                    }
                    Slider(value: viewModel.settings.qualityGuardThresholdBinding, in: 0.70...0.99, step: 0.01)
                }
                VibeHintText(text: "Quality Guard warns when SSIM drops below the threshold and offers a choice.")
            }

            VibeSettingsCard(title: "Command Line Tool", icon: "terminal") {
                HStack {
                    VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.xs) {
                        Text("Install CLI")
                            .font(VibeCheckTheme.Typography.body)
                            .foregroundColor(VibeCheckTheme.Colors.textPrimary)
                        Text(cliInstallStatus)
                            .font(VibeCheckTheme.Typography.caption)
                            .foregroundColor(cliInstalled ? VibeCheckTheme.Colors.statusOk : VibeCheckTheme.Colors.textTertiary)
                    }
                    Spacer()
                    Button(cliInstalled ? "Reinstall" : "Install") {
                        installCLI()
                    }
                    .buttonStyle(.bordered)
                }
                VibeHintText(text: "Creates a symlink at /usr/local/bin/clipslim so you can run 'clipslim' from any terminal. Requires admin password.")
            }

            VibeSettingsCard(title: "Onboarding", icon: "sparkles") {
                Button("Run onboarding again") {
                    viewModel.runOnboardingAgain()
                }
                .buttonStyle(.bordered)
                VibeHintText(text: "Run onboarding to re-pick format, folder watching, and save destination.")
            }
        }
    }

    private var cliInstalled: Bool {
        FileManager.default.fileExists(atPath: "/usr/local/bin/clipslim")
    }

    private var cliInstallStatus: String {
        cliInstalled ? "Installed at /usr/local/bin/clipslim" : "Not installed"
    }

    private func installCLI() {
        guard let appPath = Bundle.main.executableURL?.deletingLastPathComponent()
            .appendingPathComponent("clipslim").path else {
            return
        }

        // Use AppleScript to get admin privileges for symlink creation
        let script = """
        do shell script "ln -sf '\(appPath)' /usr/local/bin/clipslim" with administrator privileges
        """
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            if let error {
                Logger.shared.error("CLI install failed: \(error)")
            } else {
                Logger.shared.app("CLI installed at /usr/local/bin/clipslim")
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

private struct ShortcutsSettingsContent: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.sm) {
            ForEach(ShortcutAction.allCases) { action in
                HStack {
                    Image(systemName: action.iconName)
                        .font(.system(size: 11))
                        .foregroundColor(VibeCheckTheme.Colors.neonCyan)
                        .frame(width: 20)

                    Text(action.displayName)
                        .font(VibeCheckTheme.Typography.body)
                        .foregroundColor(VibeCheckTheme.Colors.textPrimary)

                    Spacer()

                    KeyRecorderView(
                        action: action,
                        binding: Binding(
                            get: {
                                viewModel.settings.shortcutBindings.binding(for: action)
                            },
                            set: { newBinding in
                                var store = viewModel.settings.shortcutBindings
                                store.setBinding(newBinding, for: action)
                                viewModel.settings.shortcutBindings = store
                            }
                        ),
                        onChanged: { newBinding in
                            viewModel.hotkeyCoordinator.updateBinding(newBinding, for: action)
                        }
                    )

                    Button {
                        var store = viewModel.settings.shortcutBindings
                        store.setBinding(action.defaultBinding, for: action)
                        viewModel.settings.shortcutBindings = store
                        viewModel.hotkeyCoordinator.updateBinding(action.defaultBinding, for: action)
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 10))
                            .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .help("Reset to default")
                }
            }

            VibeHintText(text: "Click a shortcut to record a new key combination. Press Esc to cancel recording.")
        }
    }
}
