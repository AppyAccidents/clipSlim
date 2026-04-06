import SwiftUI
import AppKit

private let accentOrange = VibeCheckTheme.Colors.neonOrange

private struct OrangeDivider: View {
    var body: some View {
        Rectangle()
            .fill(accentOrange.opacity(0.35))
            .frame(height: 1)
            .padding(.vertical, 2)
    }
}

struct OverlayView: View {
    @Environment(OverlayService.self) private var overlayService
    @Environment(\.openSettings) private var openSettings

    @State private var formatSelection: ImageFormat = .jpeg
    @State private var targetWidth: Int = 512
    @State private var targetHeight: Int = 512
    @State private var cropShape: CropShape = .square
    @State private var cropSize: Int = 512
    @State private var dominantHexCodes: [String] = []
    @State private var dominantCGColors: [CGColor] = []
    @State private var copiedHex: String? = nil
    @State private var ssimScore: Double? = nil

    private let minResizeDimension = 16
    private let maxResizeDimension = 8192
    private let blockSpacing = VibeCheckTheme.Spacing.md

    private enum ResizePreset: Int, CaseIterable, Identifiable {
        case p128 = 128, p256 = 256, p512 = 512
        var id: Int { rawValue }
        var label: String { "\(rawValue)×\(rawValue)" }
    }

    private enum CropPreset: Int, CaseIterable, Identifiable {
        case p256 = 256, p512 = 512, p1024 = 1024
        var id: Int { rawValue }
        var label: String { "\(rawValue)" }
    }

    var body: some View {
        Group {
            if let item = overlayService.currentItem {
                content(item)
            }
        }
        .animation(NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? nil : .easeInOut(duration: 0.16), value: overlayService.currentItem?.result.optimizedSize)
        .font(VibeCheckTheme.Typography.body)
        .tint(accentOrange)
        .onHover { hovering in
            if hovering { overlayService.pauseDismiss() } else { overlayService.resumeDismiss() }
        }
        .onChange(of: overlayService.currentItem?.result.optimizedSize) { _, _ in
            syncSelectionFromCurrentItem()
        }
        .onChange(of: overlayService.currentItem?.optimizedData) { _, newData in
            if let data = newData { extractColors(from: data) }
        }
    }

    private func content(_ item: OverlayItem) -> some View {
        VStack(alignment: .leading, spacing: blockSpacing) {
            header

            // F1: Context-aware suggestion banner
            if let presetName = item.suggestedPresetName, let appName = item.suggestedAppName {
                suggestionBanner(appName: appName, presetName: presetName)
            }

            // F6: Duplicate detected badge
            if item.isDuplicate {
                duplicateBadge
            }

            summary(item)

            // F3: Quality score badge (visible to all users when below threshold)
            if let score = item.qualityScore {
                qualityBadge(score: score, belowThreshold: item.qualityBelowThreshold)
            }

            OrangeDivider()
            primaryActions
            if item.pdfPageCount == nil {
                OrangeDivider()
                formatSection
                OrangeDivider()
                resizeSection
                OrangeDivider()
                cropSection
                OrangeDivider()
                colorsSection
            }
            if showDevDetails {
                OrangeDivider()
                devDetailsSection(item)
            }
        }
        .padding(VibeCheckTheme.Spacing.xl)
        .frame(width: 392)
        .background(
            ZStack {
                Color(hex: "111116").opacity(0.82)
                Rectangle().fill(.ultraThinMaterial)
            }
        )
        .cornerRadius(VibeCheckTheme.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: VibeCheckTheme.CornerRadius.lg)
                .stroke(
                    LinearGradient(
                        colors: [accentOrange.opacity(0.45), accentOrange.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.55), radius: 24, x: 0, y: 8)
        .shadow(color: accentOrange.opacity(0.08), radius: 12, x: 0, y: 0)
        .onAppear {
            syncSelectionFromCurrentItem()
            extractColors(from: item.optimizedData)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: VibeCheckTheme.Spacing.sm) {
            Image(systemName: "scissors")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(VibeCheckTheme.Colors.neonCyan)

            Text("Clip has been Slimmed")
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

    // MARK: - Summary

    private func summary(_ item: OverlayItem) -> some View {
        HStack(alignment: .top, spacing: VibeCheckTheme.Spacing.md) {
            if item.pdfPageCount != nil {
                pdfPreview
            } else {
                preview(data: item.optimizedData)
            }

            VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.xs) {
                Text("\(item.result.formattedOriginalSize) → \(item.result.formattedOptimizedSize)")
                    .font(VibeCheckTheme.Typography.body)
                    .foregroundColor(VibeCheckTheme.Colors.textPrimary)
                    .lineLimit(1)

                Text("\(formattedSavings(item.result)) smaller")
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.statusOk)

                if let pageCount = item.pdfPageCount {
                    Text("PDF · \(pageCount) page\(pageCount == 1 ? "" : "s")")
                        .font(VibeCheckTheme.Typography.caption)
                        .foregroundColor(VibeCheckTheme.Colors.textSecondary)
                } else {
                    Text("\(item.result.optimizedDimensions.width)×\(item.result.optimizedDimensions.height) · \(item.result.format.rawValue)")
                        .font(VibeCheckTheme.Typography.caption)
                        .foregroundColor(VibeCheckTheme.Colors.textSecondary)
                }
            }

            Spacer()
        }
    }

    private var pdfPreview: some View {
        ZStack {
            Color.white.opacity(0.06)
            Image(systemName: "doc.richtext")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(accentOrange)
        }
        .frame(width: 72, height: 72)
        .cornerRadius(VibeCheckTheme.CornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: VibeCheckTheme.CornerRadius.sm)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
    }

    // MARK: - Primary Actions

    private var primaryActions: some View {
        HStack(spacing: VibeCheckTheme.Spacing.sm) {
            actionButton("Undo", icon: "arrow.uturn.backward", isOrange: false) {
                overlayService.onUndo?()
            }
            actionButton("Save As", icon: "square.and.arrow.down", isOrange: false) {
                overlayService.onSaveAs?()
            }
            actionButton("Remove", icon: "xmark.bin", isOrange: true) {
                overlayService.onRemoveClipboardImage?()
            }
        }
    }

    // MARK: - Format Section

    private var formatSection: some View {
        VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.xs) {
            sectionLabel("FORMAT")
            Picker("Format", selection: $formatSelection) {
                Text("JPEG").tag(ImageFormat.jpeg)
                Text("PNG").tag(ImageFormat.png)
                Text("WebP").tag(ImageFormat.webp)
                Text("AVIF").tag(ImageFormat.avif)
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 174)

            applyButton("Apply Format") {
                overlayService.onApplyFormatOverride?(formatSelection)
            }
        }
    }

    // MARK: - Resize Section

    private var resizeSection: some View {
        VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.xs) {
            sectionLabel("RESIZE")

            HStack(spacing: VibeCheckTheme.Spacing.sm) {
                dimensionStepper(title: "W", value: $targetWidth)
                dimensionStepper(title: "H", value: $targetHeight)
            }

            HStack(spacing: VibeCheckTheme.Spacing.xs) {
                ForEach(ResizePreset.allCases) { preset in
                    let isSelected = targetWidth == preset.rawValue && targetHeight == preset.rawValue
                    presetChip(label: preset.label, isSelected: isSelected) {
                        targetWidth = preset.rawValue
                        targetHeight = preset.rawValue
                    }
                }
                Spacer()
            }

            applyButton("Apply Size") {
                overlayService.onApplyResizeOverride?(targetWidth, targetHeight)
            }
        }
    }

    // MARK: - Crop Section

    private var cropSection: some View {
        VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.xs) {
            sectionLabel("CROP")

            HStack(spacing: VibeCheckTheme.Spacing.sm) {
                Picker("Shape", selection: $cropShape) {
                    ForEach(CropShape.allCases, id: \.self) { shape in
                        Text(shape.rawValue).tag(shape)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 116)

                Stepper(value: $cropSize, in: 16...8192, step: 16) {
                    Text(cropShape == .square
                         ? "\(cropSize)×\(cropSize)"
                         : "⌀\(cropSize) px")
                        .font(VibeCheckTheme.Typography.monospacedFont)
                        .foregroundColor(VibeCheckTheme.Colors.textSecondary)
                }
            }

            HStack(spacing: VibeCheckTheme.Spacing.xs) {
                ForEach(CropPreset.allCases) { preset in
                    let isSelected = cropSize == preset.rawValue
                    presetChip(label: preset.label, isSelected: isSelected) {
                        cropSize = preset.rawValue
                    }
                }
                Spacer()
            }

            applyButton("Apply Crop") {
                overlayService.onApplyCrop?(cropShape, cropSize)
            }
        }
    }

    // MARK: - Colors Section

    private var colorsSection: some View {
        VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.xs) {
            sectionLabel("COLORS")

            if dominantHexCodes.isEmpty {
                Text("Extracting…")
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
            } else {
                HStack(spacing: VibeCheckTheme.Spacing.md) {
                    ForEach(dominantHexCodes.indices, id: \.self) { i in
                        colorSwatch(
                            hex: dominantHexCodes[i],
                            cgColor: i < dominantCGColors.count ? dominantCGColors[i] : nil
                        )
                    }
                    Spacer()
                }
            }
        }
    }

    private func colorSwatch(hex: String, cgColor: CGColor?) -> some View {
        let swatchColor: Color = cgColor.map { Color($0) } ?? Color.gray
        let isCopied = copiedHex == hex
        return Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(hex, forType: .string)
            copiedHex = hex
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if copiedHex == hex { copiedHex = nil }
            }
        } label: {
            HStack(spacing: VibeCheckTheme.Spacing.xs) {
                Circle()
                    .fill(swatchColor)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                Text(isCopied ? "Copied!" : hex)
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(isCopied ? VibeCheckTheme.Colors.statusOk : VibeCheckTheme.Colors.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Suggestion Banner (F1)

    private func suggestionBanner(appName: String, presetName: String) -> some View {
        HStack(spacing: VibeCheckTheme.Spacing.sm) {
            Image(systemName: "sparkle")
                .foregroundColor(VibeCheckTheme.Colors.neonOrange)
                .font(.system(size: 11))
            Text("\(appName) detected — use \(presetName)?")
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(VibeCheckTheme.Colors.textPrimary)
                .lineLimit(1)
            Spacer()
            Button("Accept") {
                overlayService.onAcceptSuggestion?()
            }
            .font(VibeCheckTheme.Typography.caption)
            .buttonStyle(.borderless)
            .foregroundColor(VibeCheckTheme.Colors.neonCyan)

            Button("Dismiss") {
                overlayService.onDismissSuggestion?()
            }
            .font(VibeCheckTheme.Typography.caption)
            .buttonStyle(.borderless)
            .foregroundColor(VibeCheckTheme.Colors.textTertiary)
        }
        .padding(VibeCheckTheme.Spacing.sm)
        .background(VibeCheckTheme.Colors.neonOrange.opacity(0.1))
        .cornerRadius(VibeCheckTheme.CornerRadius.sm)
    }

    // MARK: - Duplicate Badge (F6)

    private var duplicateBadge: some View {
        HStack(spacing: VibeCheckTheme.Spacing.sm) {
            Image(systemName: "doc.on.doc.fill")
                .foregroundColor(VibeCheckTheme.Colors.warning)
                .font(.system(size: 11))
            Text("Duplicate detected")
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(VibeCheckTheme.Colors.warning)
            Spacer()
            Button("Reuse Previous") {
                overlayService.onReuseDuplicate?()
            }
            .font(VibeCheckTheme.Typography.caption)
            .buttonStyle(.borderless)
            .foregroundColor(VibeCheckTheme.Colors.neonCyan)
        }
        .padding(VibeCheckTheme.Spacing.sm)
        .background(VibeCheckTheme.Colors.warning.opacity(0.1))
        .cornerRadius(VibeCheckTheme.CornerRadius.sm)
    }

    // MARK: - Quality Badge (F3)

    private func qualityBadge(score: Double, belowThreshold: Bool) -> some View {
        HStack(spacing: VibeCheckTheme.Spacing.sm) {
            Image(systemName: belowThreshold ? "exclamationmark.triangle" : "checkmark.shield")
                .foregroundColor(belowThreshold ? VibeCheckTheme.Colors.warning : VibeCheckTheme.Colors.statusOk)
                .font(.system(size: 11))
            Text("\(Int(score * 100))% match")
                .font(VibeCheckTheme.Typography.monospacedBold)
                .foregroundColor(belowThreshold ? VibeCheckTheme.Colors.warning : VibeCheckTheme.Colors.statusOk)
            if belowThreshold {
                Spacer()
                Text("Quality below threshold")
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.warning)
            }
        }
    }

    // MARK: - Dev Details (F8)

    private var showDevDetails: Bool {
        // Access AppSettings via a lightweight check — dev mode is a UserDefaults bool
        UserDefaults.standard.bool(forKey: "developerModeEnabled")
    }

    private func devDetailsSection(_ item: OverlayItem) -> some View {
        VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.xs) {
            sectionLabel("DEV INFO")

            Group {
                devRow("Original", item.result.preciseOriginalSize)
                devRow("Optimized", item.result.preciseOptimizedSize)
                devRow("Duration", String(format: "%.1fms", item.result.duration * 1000))
                devRow("Format", item.result.format.rawValue)
                devRow("Orig dims", "\(item.result.originalDimensions.width)x\(item.result.originalDimensions.height)")
                devRow("Opt dims", "\(item.result.optimizedDimensions.width)x\(item.result.optimizedDimensions.height)")

                if let reason = item.result.formatReason {
                    devRow("Reason", reason)
                }
                if let ct = item.result.contentType {
                    devRow("Content", ct)
                }
                if let ssim = item.result.ssimScore {
                    devRow("SSIM", String(format: "%.4f", ssim))
                }
                if let strategy = item.result.strategyUsed {
                    devRow("Strategy", strategy)
                }
            }

            if let score = ssimScore {
                HStack(spacing: VibeCheckTheme.Spacing.xs) {
                    Text("Quality Match")
                        .font(VibeCheckTheme.Typography.caption)
                        .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                    Text("\(Int(score * 100))%")
                        .font(VibeCheckTheme.Typography.monospacedBold)
                        .foregroundColor(score >= 0.90 ? VibeCheckTheme.Colors.statusOk : VibeCheckTheme.Colors.warning)
                }
            }
        }
        .onAppear {
            computeSSIM(original: item.originalData, optimized: item.optimizedData)
        }
    }

    private func devRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                .frame(width: 70, alignment: .leading)
            Text(value)
                .font(VibeCheckTheme.Typography.monospacedFont)
                .foregroundColor(VibeCheckTheme.Colors.textSecondary)
                .lineLimit(1)
        }
    }

    private func computeSSIM(original: Data, optimized: Data) {
        Task.detached(priority: .utility) {
            let score = QualityScorer.shared.computeSSIM(original: original, optimized: optimized)
            await MainActor.run {
                self.ssimScore = score
            }
        }
    }

    // MARK: - Shared Components

    private func actionButton(_ title: String, icon: String, isOrange: Bool, action: @escaping () -> Void) -> some View {
        let color: Color = isOrange ? accentOrange : VibeCheckTheme.Colors.neonCyan
        return Button(action: action) {
            HStack(spacing: VibeCheckTheme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(title)
                    .font(VibeCheckTheme.Typography.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, VibeCheckTheme.Spacing.sm)
            .padding(.vertical, VibeCheckTheme.Spacing.sm)
            .foregroundColor(color)
            .background(Color.white.opacity(0.07))
            .cornerRadius(VibeCheckTheme.CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: VibeCheckTheme.CornerRadius.sm)
                    .stroke(color.opacity(0.55), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func applyButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(VibeCheckTheme.Colors.neonCyan)
        }
        .buttonStyle(.plain)
        .padding(.leading, VibeCheckTheme.Spacing.xs)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(VibeCheckTheme.Typography.tiny)
            .foregroundColor(VibeCheckTheme.Colors.textTertiary)
            .tracking(1.2)
    }

    private func presetChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(isSelected ? VibeCheckTheme.Colors.backgroundPrimary : VibeCheckTheme.Colors.textSecondary)
                .padding(.horizontal, VibeCheckTheme.Spacing.sm)
                .padding(.vertical, VibeCheckTheme.Spacing.xs)
                .background(isSelected ? accentOrange : Color.white.opacity(0.07))
                .cornerRadius(VibeCheckTheme.CornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: VibeCheckTheme.CornerRadius.sm)
                        .stroke(isSelected ? accentOrange : Color.white.opacity(0.18), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func dimensionStepper(title: String, value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.xs) {
            Text(title)
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(VibeCheckTheme.Colors.textTertiary)
            Stepper(value: value, in: minResizeDimension...maxResizeDimension, step: 16) {
                Text("\(value.wrappedValue) px")
                    .font(VibeCheckTheme.Typography.monospacedFont)
                    .foregroundColor(VibeCheckTheme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        .frame(width: 72, height: 72)
        .background(Color.white.opacity(0.06))
        .cornerRadius(VibeCheckTheme.CornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: VibeCheckTheme.CornerRadius.sm)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
    }

    private func formattedSavings(_ result: OptimizationResult) -> String {
        let percent = result.savingsPercentage < 1
            ? String(format: "%.2f%%", result.savingsPercentage)
            : String(format: "%.1f%%", result.savingsPercentage)
        let bytes = ByteCountFormatter.string(fromByteCount: Int64(result.savingsBytes), countStyle: .file)
        return "\(percent) (\(bytes))"
    }

    private func syncSelectionFromCurrentItem() {
        guard let item = overlayService.currentItem else { return }
        formatSelection = item.formatOverrideSelection
        targetWidth = item.result.optimizedDimensions.width
        targetHeight = item.result.optimizedDimensions.height
    }

    private func extractColors(from data: Data) {
        dominantHexCodes = []
        dominantCGColors = []
        Task.detached(priority: .utility) {
            let results = ImageOptimizer.shared.dominantColors(data: data, maxColors: 3)
            let hexes = results.map { $0.hex }
            let colors = results.map { $0.cgColor }
            await MainActor.run {
                self.dominantHexCodes = hexes
                self.dominantCGColors = colors
            }
        }
    }
}
