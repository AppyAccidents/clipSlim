import SwiftUI
import AppKit

struct OnboardingFlowView: View {
    @Environment(AppViewModel.self) private var viewModel

    @State private var step = 1
    @State private var selectedFormat: ImageFormat = .jpeg
    @State private var selectedIntensity: OptimizationIntensity = .moderate
    @State private var selectedFolders: [WatchedFolder] = []
    @State private var selectedSaveDestinationMode: SaveDestinationMode = .customFolder
    @State private var customSaveFolderPath: String = ""

    var onComplete: (() -> Void)?

    private let totalSteps = 4
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
        .frame(width: 560, height: 540)
        .background(VibeCheckTheme.Colors.background)
        .preferredColorScheme(.dark)
        .onAppear {
            selectedFormat = viewModel.settings.preferredOutputFormat
            selectedIntensity = viewModel.settings.optimizationIntensity
            selectedFolders = viewModel.settings.watchedFolders
            selectedSaveDestinationMode = viewModel.settings.saveDestinationMode
            customSaveFolderPath = viewModel.settings.saveFolderPath
        }
    }

    private var header: some View {
        HStack {
            Text("Welcome to ClipSlim")
                .font(VibeCheckTheme.Typography.title)
                .foregroundColor(VibeCheckTheme.Colors.textPrimary)
            Spacer()
            Text("Step \(step)/\(totalSteps)")
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
        case 3:
            stepThree
        default:
            stepFour
        }
    }

    private var canAdvanceFromCurrentStep: Bool {
        if step == 3 {
            return !customSaveFolderPath.isEmpty
        }
        return true
    }

    private var footer: some View {
        HStack {
            if step > 1 {
                VibeButton("Back", style: .secondary) {
                    step -= 1
                }
            }

            Spacer()

            if step < totalSteps {
                VibeButton("Next") {
                    guard canAdvanceFromCurrentStep else { return }
                    step += 1
                }
                .disabled(!canAdvanceFromCurrentStep)
            } else {
                VibeButton("Finish") {
                    viewModel.completeOnboarding(
                        preferredFormat: selectedFormat,
                        optimizationIntensity: selectedIntensity,
                        folders: selectedFolders,
                        saveDestinationMode: selectedSaveDestinationMode,
                        customSaveFolderPath: customSaveFolderPath
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
            Text("How should ClipSlim export by default?")
                .font(VibeCheckTheme.Typography.headline)
                .foregroundColor(VibeCheckTheme.Colors.textPrimary)

            VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.sm) {
                formatCard(format: .jpeg, subtitle: "Smaller files, no transparency")
                formatCard(format: .png, subtitle: "Larger files, keeps transparency")
            }

            Text("If JPEG is selected and an image has transparency, ClipSlim force-switches to PNG.")
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(VibeCheckTheme.Colors.textTertiary)

            Text("How intense should JPEG optimization be?")
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
            Text("Want folder watch chaos too?")
                .font(VibeCheckTheme.Typography.headline)
                .foregroundColor(VibeCheckTheme.Colors.textPrimary)

            Text("Add one or more folders. You can skip and do this later in Settings.")
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

    private var stepThree: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            Text("Where should saved files go?")
                .font(VibeCheckTheme.Typography.headline)
                .foregroundColor(VibeCheckTheme.Colors.textPrimary)

            Text("Pick your default save strategy. ClipSlim keeps originals and optimized files in separate subfolders.")
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(VibeCheckTheme.Colors.textSecondary)

            saveDestinationCard(
                title: SaveDestinationMode.sameFolder.title,
                subtitle: "Use the original file's folder when possible.",
                mode: .sameFolder
            )

            saveDestinationCard(
                title: SaveDestinationMode.customFolder.title,
                subtitle: "Use one dedicated folder you control.",
                mode: .customFolder
            )

            if selectedSaveDestinationMode == .customFolder {
                HStack {
                    Text(customSaveFolderPath.isEmpty ? "No custom folder selected" : customSaveFolderPath)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .font(VibeCheckTheme.Typography.caption)
                        .foregroundColor(VibeCheckTheme.Colors.textSecondary)
                    Spacer()
                    VibeButton("Choose Folder", style: .secondary) {
                        chooseCustomSaveFolder()
                    }
                }
            } else {
                HStack {
                    Text(customSaveFolderPath.isEmpty ? "No fallback custom folder selected" : "Fallback folder: \(customSaveFolderPath)")
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .font(VibeCheckTheme.Typography.caption)
                        .foregroundColor(VibeCheckTheme.Colors.textSecondary)
                    Spacer()
                    VibeButton("Set Fallback", style: .secondary) {
                        chooseCustomSaveFolder()
                    }
                }
            }

            if customSaveFolderPath.isEmpty {
                Text("Pick a custom folder to continue (it's also the clipboard fallback).")
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.warning)
            }
        }
    }

    private var stepFour: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            Text("All set")
                .font(VibeCheckTheme.Typography.headline)
                .foregroundColor(VibeCheckTheme.Colors.textPrimary)

            Text("ClipSlim now lives in the menu bar, ready to politely wreck oversized images.")
                .font(VibeCheckTheme.Typography.body)
                .foregroundColor(VibeCheckTheme.Colors.textSecondary)

            VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.sm) {
                hintRow(icon: "menubar.rectangle", text: "Menu bar icon = quick toggles, pause controls, and stats.")
                hintRow(icon: "keyboard", text: "Hotkeys: Option+1 copies optimized, Option+2 restores original.")
                hintRow(icon: "lock.shield", text: "Everything runs locally on your Mac. No cloud detours.")
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

    private func chooseCustomSaveFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose where ClipSlim should save output files"
        panel.prompt = "Select Folder"

        if panel.runModal() == .OK, let url = panel.url {
            customSaveFolderPath = url.path
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

    private func saveDestinationCard(title: String, subtitle: String, mode: SaveDestinationMode) -> some View {
        Button {
            selectedSaveDestinationMode = mode
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.xs) {
                    Text(title)
                        .font(VibeCheckTheme.Typography.body)
                        .foregroundColor(VibeCheckTheme.Colors.textPrimary)
                    Text(subtitle)
                        .font(VibeCheckTheme.Typography.caption)
                        .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                }
                Spacer()
                Image(systemName: selectedSaveDestinationMode == mode ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selectedSaveDestinationMode == mode ? VibeCheckTheme.Colors.neonCyan : VibeCheckTheme.Colors.textTertiary)
            }
            .padding(VibeCheckTheme.Spacing.md)
            .background(VibeCheckTheme.Colors.surface)
            .cornerRadius(VibeCheckTheme.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: VibeCheckTheme.CornerRadius.md)
                    .stroke(selectedSaveDestinationMode == mode ? VibeCheckTheme.Colors.neonCyan.opacity(0.6) : VibeCheckTheme.Colors.border, lineWidth: 1)
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
