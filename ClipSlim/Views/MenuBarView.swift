import SwiftUI

struct MenuBarView: View {

    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow

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
        .tint(VibeCheckTheme.Colors.neonCyan)
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
                viewModel.refreshPauseState()
            }

            QuickToggleRow(
                icon: "folder",
                title: "Folder Watch",
                isOn: viewModel.settings.folderWatchEnabledBinding,
                accentColor: VibeCheckTheme.Colors.neonOrange
            )
            .onChange(of: viewModel.settings.folderWatchEnabled) { _, _ in
                viewModel.refreshPauseState()
            }

            QuickToggleRow(
                icon: "moon.zzz",
                title: "Focus Mode",
                isOn: viewModel.settings.focusModeEnabledBinding,
                accentColor: VibeCheckTheme.Colors.warning
            )
            .onChange(of: viewModel.settings.focusModeEnabled) { _, _ in
                viewModel.refreshPauseState()
            }
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

            PresetPicker(selectedPreset: viewModel.settings.selectedPresetBinding)

            HStack {
                Text("Quality: \(Int(viewModel.settings.currentQuality * 100))%")
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.textSecondary)
                Spacer()
                Text("Polling: \(String(format: "%.1fs", viewModel.clipboardWatcher.currentPollInterval))")
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.textSecondary)
            }
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
                label: "Optimized",
                value: "\(viewModel.totalOptimized)"
            )

            StatsRow(
                icon: "arrow.down.circle",
                label: "Total Saved",
                value: ByteCountFormatter.string(fromByteCount: Int64(viewModel.totalSaved), countStyle: .file),
                valueColor: VibeCheckTheme.Colors.success
            )
        }
        .padding(.horizontal, VibeCheckTheme.Spacing.lg)
        .padding(.vertical, VibeCheckTheme.Spacing.md)
    }

    private var pauseSection: some View {
        VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.xs) {
            Text("\(viewModel.pauseStatusText)")
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(VibeCheckTheme.Colors.textSecondary)

            HStack {
                Button("Pause 10m") { viewModel.pauseFor(minutes: 10) }
                Button("Pause 1h") { viewModel.pauseFor(hours: 1) }
                Button("Until Tomorrow") { viewModel.pauseUntilTomorrow() }
                Button("Resume") { viewModel.resumeFromPause() }
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
            MenuActionButton(icon: "arrow.uturn.backward", title: "Undo Last Optimization") {
                viewModel.undoLastOptimization()
            }

            MenuActionButton(icon: "cup.and.saucer.fill", title: "Buy me a coffee…") {
                openSettings()
            }

            MenuActionButton(icon: "clock.arrow.circlepath", title: "Debug Log") {
                openWindow(id: "debug-log")
            }

            MenuActionButton(icon: "gearshape", title: "Settings…") {
                openSettings()
            }

            MenuActionButton(icon: "trash", title: "Clear History", iconColor: VibeCheckTheme.Colors.warning) {
                viewModel.clearHistory()
            }

            VibeDivider()

            MenuActionButton(icon: "power", title: "Quit ClipSlim", iconColor: VibeCheckTheme.Colors.error) {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.vertical, VibeCheckTheme.Spacing.xs)
    }
}
