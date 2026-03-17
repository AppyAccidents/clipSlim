import SwiftUI

struct MenuBarView: View {

    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow

    private var folderWatchBinding: Binding<Bool> {
        Binding(
            get: { viewModel.settings.folderWatchEnabled },
            set: { viewModel.setFolderWatchEnabled($0) }
        )
    }

    private var pauseViewState: MenuPauseViewState {
        MenuPauseViewState(isPaused: viewModel.settings.isPausedNow)
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            VibeDivider()

            togglesSection

            VibeDivider()

            presetSection

            VibeDivider()

            statsSection

            VibeDivider()

            pauseSection

            VibeDivider()

            if let error = viewModel.lastError {
                errorBanner(error)
                VibeDivider()
            }

            actionsSection
        }
        .frame(width: 340)
        .font(VibeCheckTheme.Typography.body)
        .tint(VibeCheckTheme.Colors.neonOrange)
        .background(VibeCheckTheme.Colors.background)
        .onAppear {
            viewModel.startServices()
        }
    }

    private var headerSection: some View {
        HStack(spacing: VibeCheckTheme.Spacing.sm) {
            Image(systemName: "scissors")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(VibeCheckTheme.Colors.neonCyan)
                .neonGlow(color: VibeCheckTheme.Colors.neonCyan, radius: 4)

            Text("ClipSlim")
                .font(VibeCheckTheme.Typography.title)
                .foregroundColor(VibeCheckTheme.Colors.textPrimary)

            Spacer()

            if viewModel.isProcessing {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 16, height: 16)
            }

            statusIndicator
        }
        .padding(.horizontal, VibeCheckTheme.Spacing.lg)
        .padding(.vertical, VibeCheckTheme.Spacing.md)
    }

    private var statusIndicator: some View {
        Circle()
            .fill(viewModel.clipboardWatcher.isWatching ? VibeCheckTheme.Colors.success : VibeCheckTheme.Colors.textTertiary)
            .frame(width: 8, height: 8)
            .if(viewModel.clipboardWatcher.isWatching) { view in
                view.neonGlow(color: VibeCheckTheme.Colors.success, radius: 4)
            }
    }

    private var togglesSection: some View {
        VStack(spacing: 0) {
            QuickToggleRow(
                icon: "doc.on.clipboard",
                title: "Clipboard Watch",
                isOn: viewModel.settings.clipboardWatchEnabledBinding
            )
            .onChange(of: viewModel.settings.clipboardWatchEnabled) { _, _ in
                viewModel.reconcileWatcherState()
            }

            QuickToggleRow(
                icon: "folder",
                title: "Folder Watch",
                isOn: folderWatchBinding
            )
        }
        .padding(.vertical, VibeCheckTheme.Spacing.xs)
    }

    private var presetSection: some View {
        VStack(spacing: VibeCheckTheme.Spacing.sm) {
            HStack {
                Text("PRESET")
                    .font(VibeCheckTheme.Typography.tiny)
                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                    .tracking(1.5)
                Spacer()
            }

            PresetButtonGroup(
                selectedPreset: viewModel.settings.selectedPresetBinding,
                labelStyle: .compact
            )

            Text("Slimming percentage: \(viewModel.settings.currentSlimmingPercentage)%")
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(VibeCheckTheme.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, VibeCheckTheme.Spacing.lg)
        .padding(.vertical, VibeCheckTheme.Spacing.md)
    }

    private var statsSection: some View {
        VStack(spacing: VibeCheckTheme.Spacing.sm) {
            HStack {
                Text("SESSION STATS")
                    .font(VibeCheckTheme.Typography.tiny)
                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                    .tracking(1.5)
                Spacer()
            }

            StatsRow(
                icon: "photo.stack",
                label: "Slimmed",
                value: "\(viewModel.totalOptimized)"
            )

            StatsRow(
                icon: "arrow.down.circle",
                label: "Bytes Rescued",
                value: ByteCountFormatter.string(fromByteCount: Int64(viewModel.totalSaved), countStyle: .file),
                valueColor: VibeCheckTheme.Colors.success
            )
        }
        .padding(.horizontal, VibeCheckTheme.Spacing.lg)
        .padding(.vertical, VibeCheckTheme.Spacing.md)
    }

    private var pauseSection: some View {
        VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.sm) {
            HStack {
                Text("FOCUS MODE")
                    .font(VibeCheckTheme.Typography.tiny)
                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                    .tracking(1.5)
                Spacer()
            }

            Text(pauseViewState.statusText)
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(VibeCheckTheme.Colors.textSecondary)

            HStack {
                Button("10m") { viewModel.pauseFor(minutes: 10) }
                    .disabled(!pauseViewState.canPause)
                Button("1h") { viewModel.pauseFor(hours: 1) }
                    .disabled(!pauseViewState.canPause)
                Button("One Day") { viewModel.pauseFor(days: 1) }
                    .disabled(!pauseViewState.canPause)
                Button("Resume") { viewModel.resumeFromPause() }
                    .disabled(!pauseViewState.canResume)
            }
            .buttonStyle(.borderless)
            .font(VibeCheckTheme.Typography.caption)
        }
        .padding(.horizontal, VibeCheckTheme.Spacing.lg)
        .padding(.vertical, VibeCheckTheme.Spacing.md)
    }

    private func errorBanner(_ error: String) -> some View {
        HStack(spacing: VibeCheckTheme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(VibeCheckTheme.Colors.error)

            Text(error)
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(VibeCheckTheme.Colors.error)
                .lineLimit(2)

            Spacer()

            Button {
                viewModel.clearLastError()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, VibeCheckTheme.Spacing.lg)
        .padding(.vertical, VibeCheckTheme.Spacing.sm)
        .background(VibeCheckTheme.Colors.error.opacity(0.1))
    }

    private var actionsSection: some View {
        VStack(spacing: 0) {
            MenuActionButton(icon: "square.and.arrow.down.on.square", title: "Drop Zone") {
                viewModel.toggleDropZone()
            }

            MenuActionButton(icon: "arrow.uturn.backward", title: "Undo Last Slimming") {
                viewModel.undoLastOptimization()
            }

            MenuActionButton(icon: "clock.badge.checkmark", title: "Clipboard History") {
                openWindow(id: "clipboard-history")
            }

            MenuActionButton(icon: "heart.fill", title: "Leave a Tip...") {
                openSettings()
            }

            MenuActionButton(icon: "clock.arrow.circlepath", title: "Debug Log (Nerd View)") {
                openWindow(id: "debug-log")
            }

            if viewModel.settings.developerModeEnabled {
                MenuActionButton(icon: "square.and.arrow.up", title: "Export Session Log") {
                    exportSessionLog()
                }
            }

            MenuActionButton(icon: "gearshape", title: "Settings…") {
                openSettings()
            }

            MenuActionButton(icon: "trash", title: "Clear History (Poof)", iconColor: VibeCheckTheme.Colors.warning) {
                viewModel.clearHistory()
            }

            VibeDivider()

            MenuActionButton(icon: "power", title: "Quit ClipSlim", iconColor: VibeCheckTheme.Colors.error) {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.vertical, VibeCheckTheme.Spacing.xs)
    }

    private func exportSessionLog() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "clipslim-session.json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? SessionLogExporter.shared.exportToFile(events: viewModel.events, url: url)
    }
}
