import SwiftUI
import AppKit

struct OnboardingFlowView: View {
    @Environment(AppViewModel.self) private var viewModel

    @State private var step = 1
    @State private var selectedFormat: ImageFormat = .jpeg
    @State private var selectedIntensity: OptimizationIntensity = .moderate
    @State private var selectedFolders: [WatchedFolder] = []

    var onComplete: (() -> Void)?

    private let contentPadding = VibeCheckTheme.Spacing.xl
    private let sectionSpacing = VibeCheckTheme.Spacing.md

    var body: some View {
        VStack(spacing: 0) {
            header
            VibeDivider()

            contentShell {
                content
            }

            VibeDivider()
            footer
        }
        .frame(width: 560, height: 500)
        .background(VibeCheckTheme.Colors.background)
        .preferredColorScheme(.dark)
        .onAppear {
            selectedFormat = viewModel.settings.preferredOutputFormat
            selectedIntensity = viewModel.settings.optimizationIntensity
            selectedFolders = viewModel.settings.watchedFolders
        }
    }

    private var header: some View {
        HStack {
            Text("Welcome to ClipSlim")
                .font(VibeCheckTheme.Typography.title)
                .foregroundColor(VibeCheckTheme.Colors.textPrimary)
            Spacer()
            Text("Step \(step)/3")
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(VibeCheckTheme.Colors.textTertiary)
        }
        .padding(.horizontal, contentPadding)
        .padding(.vertical, VibeCheckTheme.Spacing.lg)
    }

    private func contentShell<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                content()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(contentPadding)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case 1:
            stepOne
        case 2:
            stepTwo
        default:
            stepThree
        }
    }

    private var footer: some View {
        HStack {
            if step > 1 {
                VibeButton("Back", style: .secondary) {
                    step -= 1
                }
            }

            Spacer()

            if step < 3 {
                VibeButton("Next") {
                    step += 1
                }
            } else {
                VibeButton("Finish") {
                    viewModel.completeOnboarding(
                        preferredFormat: selectedFormat,
                        optimizationIntensity: selectedIntensity,
                        folders: selectedFolders
                    )
                    onComplete?()
                }
            }
        }
        .padding(.horizontal, contentPadding)
        .padding(.vertical, VibeCheckTheme.Spacing.lg)
    }

    private var stepOne: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            Text("What should ClipSlim output by default?")
                .font(VibeCheckTheme.Typography.headline)
                .foregroundColor(VibeCheckTheme.Colors.textPrimary)

            VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.sm) {
                formatCard(format: .jpeg, subtitle: "Smaller files, no transparency")
                formatCard(format: .png, subtitle: "Larger files, preserves transparency")
            }

            Text("If JPEG is selected and an image has transparency, ClipSlim forces PNG to preserve alpha.")
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(VibeCheckTheme.Colors.textTertiary)

            Text("How aggressively should ClipSlim optimize JPEG output?")
                .font(VibeCheckTheme.Typography.headline)
                .foregroundColor(VibeCheckTheme.Colors.textPrimary)
                .padding(.top, VibeCheckTheme.Spacing.sm)

            VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.sm) {
                intensityCard(.aggressive)
                intensityCard(.moderate)
                intensityCard(.light)
            }
        }
    }

    private var stepTwo: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            Text("Watch folders?")
                .font(VibeCheckTheme.Typography.headline)
                .foregroundColor(VibeCheckTheme.Colors.textPrimary)

            Text("Add one or more folders. You can skip and configure this later in Settings.")
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(VibeCheckTheme.Colors.textSecondary)

            folderListCard

            HStack(spacing: VibeCheckTheme.Spacing.sm) {
                VibeButton("Add Folder", icon: "plus", style: .secondary) {
                    let panel = NSOpenPanel()
                    panel.canChooseDirectories = true
                    panel.canChooseFiles = false
                    panel.allowsMultipleSelection = true
                    panel.prompt = "Add"
                    if panel.runModal() == .OK {
                        for url in panel.urls {
                            if let watched = try? FolderBookmarkManager.makeWatchedFolder(from: url),
                               !selectedFolders.contains(where: { $0.displayName == watched.displayName }) {
                                selectedFolders.append(watched)
                            }
                        }
                    }
                }

                VibeButton("Skip", style: .secondary) {
                    selectedFolders = []
                    step = 3
                }
            }
        }
    }

    private var folderListCard: some View {
        ScrollView {
            VStack(spacing: 0) {
                if selectedFolders.isEmpty {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                            .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                        Text("No folders selected yet")
                            .font(VibeCheckTheme.Typography.caption)
                            .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                        Spacer()
                    }
                    .padding(VibeCheckTheme.Spacing.md)
                } else {
                    ForEach(selectedFolders) { folder in
                        HStack(spacing: VibeCheckTheme.Spacing.sm) {
                            Image(systemName: "folder")
                                .foregroundColor(VibeCheckTheme.Colors.neonCyan)
                                .frame(width: 18)

                            Text(folder.displayName)
                                .font(VibeCheckTheme.Typography.body)
                                .foregroundColor(VibeCheckTheme.Colors.textPrimary)
                                .lineLimit(1)

                            Spacer()

                            Button {
                                selectedFolders.removeAll { $0.id == folder.id }
                            } label: {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, VibeCheckTheme.Spacing.md)
                        .padding(.vertical, VibeCheckTheme.Spacing.sm)

                        if folder.id != selectedFolders.last?.id {
                            VibeDivider()
                        }
                    }
                }
            }
        }
        .frame(height: 156)
        .background(VibeCheckTheme.Colors.surface)
        .cornerRadius(VibeCheckTheme.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: VibeCheckTheme.CornerRadius.md)
                .stroke(VibeCheckTheme.Colors.border, lineWidth: 1)
        )
    }

    private var stepThree: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            Text("All set")
                .font(VibeCheckTheme.Typography.headline)
                .foregroundColor(VibeCheckTheme.Colors.textPrimary)

            Text("ClipSlim runs from the menu bar and stays in the background.")
                .font(VibeCheckTheme.Typography.body)
                .foregroundColor(VibeCheckTheme.Colors.textSecondary)

            VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.sm) {
                hintRow(icon: "menubar.rectangle", text: "Use the menu bar icon for pause/focus/rules quickly.")
                hintRow(icon: "keyboard", text: "Hotkeys: Option+1 copy last optimized, Option+2 copy last original.")
                hintRow(icon: "lock.shield", text: "All optimization runs locally on your Mac.")
            }
        }
    }

    private func formatCard(format: ImageFormat, subtitle: String) -> some View {
        Button {
            selectedFormat = format
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.xs) {
                    Text(format.rawValue)
                        .font(VibeCheckTheme.Typography.body)
                        .foregroundColor(VibeCheckTheme.Colors.textPrimary)
                    Text(subtitle)
                        .font(VibeCheckTheme.Typography.caption)
                        .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                }
                Spacer()
                Image(systemName: selectedFormat == format ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selectedFormat == format ? VibeCheckTheme.Colors.neonCyan : VibeCheckTheme.Colors.textTertiary)
            }
            .padding(VibeCheckTheme.Spacing.md)
            .background(VibeCheckTheme.Colors.surface)
            .cornerRadius(VibeCheckTheme.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: VibeCheckTheme.CornerRadius.md)
                    .stroke(selectedFormat == format ? VibeCheckTheme.Colors.neonCyan.opacity(0.6) : VibeCheckTheme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func hintRow(icon: String, text: String) -> some View {
        HStack(spacing: VibeCheckTheme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(VibeCheckTheme.Colors.neonCyan)
                .frame(width: 20)
            Text(text)
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(VibeCheckTheme.Colors.textSecondary)
        }
    }

    private func intensityCard(_ intensity: OptimizationIntensity) -> some View {
        Button {
            selectedIntensity = intensity
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.xs) {
                    Text(intensity.title)
                        .font(VibeCheckTheme.Typography.body)
                        .foregroundColor(VibeCheckTheme.Colors.textPrimary)
                    Text("\(intensity.summary) · JPEG quality \(Int(intensity.qualityValue * 100))%")
                        .font(VibeCheckTheme.Typography.caption)
                        .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                }
                Spacer()
                Image(systemName: selectedIntensity == intensity ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selectedIntensity == intensity ? VibeCheckTheme.Colors.neonCyan : VibeCheckTheme.Colors.textTertiary)
            }
            .padding(VibeCheckTheme.Spacing.md)
            .background(VibeCheckTheme.Colors.surface)
            .cornerRadius(VibeCheckTheme.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: VibeCheckTheme.CornerRadius.md)
                    .stroke(selectedIntensity == intensity ? VibeCheckTheme.Colors.neonCyan.opacity(0.6) : VibeCheckTheme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
