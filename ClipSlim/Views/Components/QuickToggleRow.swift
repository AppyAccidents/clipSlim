import SwiftUI

struct QuickToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    var accentColor: Color = VibeCheckTheme.Colors.neonOrange
    
    var body: some View {
        HStack(spacing: VibeCheckTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(isOn ? accentColor : VibeCheckTheme.Colors.textTertiary)
                .frame(width: 20)
            
            Text(title)
                .font(VibeCheckTheme.Typography.body)
                .foregroundColor(VibeCheckTheme.Colors.textPrimary)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .tint(accentColor)
                .labelsHidden()
                .scaleEffect(0.8)
        }
        .padding(.horizontal, VibeCheckTheme.Spacing.md)
        .padding(.vertical, VibeCheckTheme.Spacing.sm)
    }
}
