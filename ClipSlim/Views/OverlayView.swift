import SwiftUI
import AppKit

struct OverlayView: View {
    @Environment(OverlayService.self) private var overlayService
    @Environment(\.openSettings) private var openSettings

    @State private var formatSelection: ImageFormat = .jpeg
    @State private var targetWidth: Int = 512
    @State private var targetHeight: Int = 512

    private let blockSpacing = VibeCheckTheme.Spacing.md
    private let minResizeDimension = 16
    private let maxResizeDimension = 8192

    private enum SquareResizePreset: Int, CaseIterable, Identifiable {
        case x128 = 128
        case x256 = 256
        case x512 = 512

        var id: Int { rawValue }
        var label: String { "\(rawValue)x\(rawValue)" }
    }

    var body: some View {
        Group {
            if let item = overlayService.currentItem {
                content(item)
            }
        }
        .animation(NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? nil : .easeInOut(duration: 0.16), value: overlayService.currentItem?.result.optimizedSize)
        .font(VibeCheckTheme.Typography.body)
        .tint(VibeCheckTheme.Colors.neonCyan)
        .onHover { hovering in
            if hovering {
                overlayService.pauseDismiss()
            } else {
                overlayService.resumeDismiss()
            }
        }
        .onChange(of: overlayService.currentItem?.result.format) { _, _ in
            syncSelectionFromCurrentItem()
        }
        .onChange(of: overlayService.currentItem?.result.optimizedDimensions.width) { _, _ in
            syncSelectionFromCurrentItem()
        }
        .onChange(of: overlayService.currentItem?.result.optimizedDimensions.height) { _, _ in
            syncSelectionFromCurrentItem()
        }
        .onChange(of: overlayService.currentItem?.result.optimizedSize) { _, _ in
            syncSelectionFromCurrentItem()
        }
    }

    private func content(_ item: OverlayItem) -> some View {
        VStack(alignment: .leading, spacing: blockSpacing) {
            header

            summary(item)

            VibeDivider()

            primaryActions

            VibeDivider()

            secondaryActions
        }
        .padding(VibeCheckTheme.Spacing.lg)
        .frame(width: 392)
        .background(VibeCheckTheme.Colors.surfaceElevated)
        .cornerRadius(VibeCheckTheme.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: VibeCheckTheme.CornerRadius.lg)
                .stroke(VibeCheckTheme.Colors.borderActive.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: VibeCheckTheme.Colors.background.opacity(0.45), radius: 10, x: 0, y: 6)
        .onAppear {
            syncSelectionFromCurrentItem()
        }
    }

    private var header: some View {
        HStack(spacing: VibeCheckTheme.Spacing.sm) {
            Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(VibeCheckTheme.Colors.neonCyan)

            Text("Optimization Complete")
                .font(VibeCheckTheme.Typography.headline)
                .foregroundColor(VibeCheckTheme.Colors.textPrimary)

            Spacer()

            Button {
                overlayService.dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                    .padding(6)
                    .background(VibeCheckTheme.Colors.surface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private func summary(_ item: OverlayItem) -> some View {
        HStack(alignment: .top, spacing: VibeCheckTheme.Spacing.md) {
            preview(data: item.optimizedData)

            VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.xs) {
                Text("\(item.result.formattedOriginalSize) -> \(item.result.formattedOptimizedSize)")
                    .font(VibeCheckTheme.Typography.body)
                    .foregroundColor(VibeCheckTheme.Colors.textPrimary)
                    .lineLimit(1)

                Text("\(item.result.preciseOriginalSize) -> \(item.result.preciseOptimizedSize)")
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                    .lineLimit(1)

                Text("\(formattedSavings(item.result)) smaller")
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.statusOk)

                Text("\(item.result.optimizedDimensions.width)x\(item.result.optimizedDimensions.height) · \(item.result.format.rawValue)")
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.textSecondary)
            }

            Spacer()
        }
    }

    private var primaryActions: some View {
        HStack(spacing: VibeCheckTheme.Spacing.sm) {
            compactAction("Undo", icon: "arrow.uturn.backward") { overlayService.onUndo?() }
            compactAction("Save As", icon: "square.and.arrow.down") { overlayService.onSaveAs?() }
            compactAction("Remove", icon: "xmark.bin") { overlayService.onRemoveClipboardImage?() }
        }
    }

    private var secondaryActions: some View {
        VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.sm) {
            HStack(spacing: VibeCheckTheme.Spacing.sm) {
                Picker("Format", selection: $formatSelection) {
                    Text("JPEG").tag(ImageFormat.jpeg)
                    Text("PNG").tag(ImageFormat.png)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 116)

                VibeButton("Apply", style: .secondary) {
                    overlayService.onApplyFormatOverride?(formatSelection)
                }

                Spacer()

                Button("Options") {
                    overlayService.onOpenSettings?()
                    openSettings()
                }
                .buttonStyle(.borderless)
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(VibeCheckTheme.Colors.textSecondary)
            }

            VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.xs) {
                Text("Resize")
                    .font(VibeCheckTheme.Typography.tiny)
                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                    .tracking(1.2)

                HStack(spacing: VibeCheckTheme.Spacing.sm) {
                    dimensionStepper(title: "W", value: $targetWidth)
                    dimensionStepper(title: "H", value: $targetHeight)

                    VibeButton("Apply Size", style: .secondary) {
                        overlayService.onApplyResizeOverride?(targetWidth, targetHeight)
                    }
                }

                HStack(spacing: VibeCheckTheme.Spacing.xs) {
                    ForEach(SquareResizePreset.allCases) { preset in
                        squarePresetButton(preset)
                    }
                    Spacer()
                }
            }

            HStack(spacing: VibeCheckTheme.Spacing.md) {
                linkAction("Ignore Image") { overlayService.onIgnoreImage?() }
                linkAction("Ignore App") { overlayService.onIgnoreApp?() }
                Spacer()
            }
        }
    }

    private func compactAction(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: VibeCheckTheme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(title)
                    .font(VibeCheckTheme.Typography.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, VibeCheckTheme.Spacing.sm)
            .padding(.vertical, VibeCheckTheme.Spacing.sm)
            .foregroundColor(VibeCheckTheme.Colors.neonCyan)
            .background(VibeCheckTheme.Colors.surface)
            .cornerRadius(VibeCheckTheme.CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: VibeCheckTheme.CornerRadius.sm)
                    .stroke(VibeCheckTheme.Colors.neonCyan.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func linkAction(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.borderless)
            .font(VibeCheckTheme.Typography.caption)
            .foregroundColor(VibeCheckTheme.Colors.textSecondary)
    }

    private func dimensionStepper(title: String, value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.xs) {
            Text(title)
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(VibeCheckTheme.Colors.textTertiary)
            Stepper(
                value: value,
                in: minResizeDimension...maxResizeDimension,
                step: 16
            ) {
                Text("\(value.wrappedValue) px")
                    .font(VibeCheckTheme.Typography.monospacedFont)
                    .foregroundColor(VibeCheckTheme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func squarePresetButton(_ preset: SquareResizePreset) -> some View {
        let isSelected = targetWidth == preset.rawValue && targetHeight == preset.rawValue
        return Button {
            targetWidth = preset.rawValue
            targetHeight = preset.rawValue
        } label: {
            Text(preset.label)
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(isSelected ? VibeCheckTheme.Colors.background : VibeCheckTheme.Colors.textSecondary)
                .padding(.horizontal, VibeCheckTheme.Spacing.sm)
                .padding(.vertical, VibeCheckTheme.Spacing.xs)
                .background(isSelected ? VibeCheckTheme.Colors.neonCyan : VibeCheckTheme.Colors.surface)
                .cornerRadius(VibeCheckTheme.CornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: VibeCheckTheme.CornerRadius.sm)
                        .stroke(isSelected ? VibeCheckTheme.Colors.neonCyan.opacity(0.6) : VibeCheckTheme.Colors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func preview(data: Data) -> some View {
        Group {
            if let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Color.gray.opacity(0.2)
            }
        }
        .frame(width: 80, height: 80)
        .background(VibeCheckTheme.Colors.backgroundCard)
        .cornerRadius(VibeCheckTheme.CornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: VibeCheckTheme.CornerRadius.sm)
                .stroke(VibeCheckTheme.Colors.border, lineWidth: 1)
        )
    }

    private func formattedSavings(_ result: OptimizationResult) -> String {
        let percent = result.savingsPercentage < 1 ? String(format: "%.2f", result.savingsPercentage) : String(format: "%.1f", result.savingsPercentage)
        let bytes = ByteCountFormatter.string(fromByteCount: Int64(result.savingsBytes), countStyle: .file)
        return "\(percent)% (\(bytes))"
    }

    private func syncSelectionFromCurrentItem() {
        guard let item = overlayService.currentItem else { return }
        formatSelection = item.formatOverrideSelection
        targetWidth = item.result.optimizedDimensions.width
        targetHeight = item.result.optimizedDimensions.height
    }
}
