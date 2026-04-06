import SwiftUI

struct PresetButtonGroup: View {
    enum LabelStyle {
        case compact
        case full
    }

    @Binding var selectedPreset: OptimizationPreset
    var labelStyle: LabelStyle = .compact
    var selectedColor: Color = VibeCheckTheme.Colors.neonCyan

    var body: some View {
        HStack(spacing: VibeCheckTheme.Spacing.xs) {
            ForEach(OptimizationPreset.allCases, id: \.self) { preset in
                presetButton(preset)
            }
        }
        .padding(VibeCheckTheme.Spacing.xs)
        .background(VibeCheckTheme.Colors.background)
        .cornerRadius(VibeCheckTheme.CornerRadius.md)
    }

    private func presetButton(_ preset: OptimizationPreset) -> some View {
        let isSelected = selectedPreset == preset

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedPreset = preset
            }
        } label: {
            Text(displayName(for: preset))
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(isSelected ? VibeCheckTheme.Colors.background : VibeCheckTheme.Colors.textSecondary)
                .padding(.horizontal, VibeCheckTheme.Spacing.sm)
                .padding(.vertical, VibeCheckTheme.Spacing.xs)
                .frame(maxWidth: .infinity)
                .background(isSelected ? selectedColor : Color.clear)
                .cornerRadius(VibeCheckTheme.CornerRadius.sm)
        }
        .buttonStyle(.plain)
    }

    private func displayName(for preset: OptimizationPreset) -> String {
        switch (labelStyle, preset) {
        case (.compact, .highQuality): return "High"
        case (.compact, .webQuality): return "Web"
        case (.compact, .compressed): return "Comp"
        case (.compact, .custom): return "Custom"
        case (.compact, .lossless): return "Lossless"
        case (.full, _): return preset.rawValue
        }
    }
}
