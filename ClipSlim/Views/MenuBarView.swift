import SwiftUI

struct MenuBarView: View {
    
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            VibeDivider()
            
            // Quick Toggles
            togglesSection
            
            VibeDivider()
            
            // Preset Picker
            presetSection
            
            VibeDivider()
            
            // Stats
            statsSection
            
            VibeDivider()
            
            // Error Banner
            if let error = viewModel.lastError {
                errorBanner(error)
                VibeDivider()
            }
            
            // Actions
            actionsSection
        }
        .frame(width: 320)
        .background(VibeCheckTheme.Colors.background)
        .onAppear {
            viewModel.startServices()
        }
    }
    
    // MARK: - Sections
    
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
            .onChange(of: viewModel.settings.clipboardWatchEnabled) { _, newValue in
                if newValue {
                    viewModel.clipboardWatcher.start()
                } else {
                    viewModel.clipboardWatcher.stop()
                }
            }
            
            QuickToggleRow(
                icon: "folder",
                title: "Folder Watch",
                isOn: viewModel.settings.folderWatchEnabledBinding,
                accentColor: VibeCheckTheme.Colors.neonOrange
            )
            .onChange(of: viewModel.settings.folderWatchEnabled) { _, newValue in
                if newValue {
                    viewModel.toggleFolderWatch()
                    viewModel.settings.folderWatchEnabled = true
                } else {
                    viewModel.folderWatcher.stop()
                }
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
            
            // Quality indicator
            HStack {
                Text("Quality: \(Int(viewModel.settings.currentQuality * 100))%")
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.textSecondary)
                Spacer()
                Text("Max: \(viewModel.settings.currentMaxDimension)px")
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
            
            if let lastEvent = viewModel.events.first {
                StatsRow(
                    icon: "clock",
                    label: "Last",
                    value: lastEvent.summary,
                    valueColor: VibeCheckTheme.Colors.neonOrange
                )
            }
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
