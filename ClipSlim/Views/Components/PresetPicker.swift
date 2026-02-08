import SwiftUI

struct PresetPicker: View {
    @Binding var selectedPreset: OptimizationPreset
    
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
            Text(preset.rawValue)
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(isSelected ? VibeCheckTheme.Colors.background : VibeCheckTheme.Colors.textSecondary)
                .padding(.horizontal, VibeCheckTheme.Spacing.sm)
                .padding(.vertical, VibeCheckTheme.Spacing.xs)
                .background(isSelected ? VibeCheckTheme.Colors.neonCyan : Color.clear)
                .cornerRadius(VibeCheckTheme.CornerRadius.sm)
        }
        .buttonStyle(.plain)
    }
}
