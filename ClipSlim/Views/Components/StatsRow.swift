import SwiftUI

struct StatsRow: View {
    let icon: String
    let label: String
    let value: String
    var valueColor: Color = VibeCheckTheme.Colors.neonCyan
    
    var body: some View {
        HStack(spacing: VibeCheckTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                .frame(width: 16)
            
            Text(label)
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(VibeCheckTheme.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(VibeCheckTheme.Typography.caption)
                .fontWeight(.semibold)
                .foregroundColor(valueColor)
        }
    }
}
