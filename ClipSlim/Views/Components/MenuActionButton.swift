import SwiftUI

struct MenuActionButton: View {
    let icon: String
    let title: String
    var iconColor: Color = VibeCheckTheme.Colors.neonCyan
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: VibeCheckTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(iconColor)
                    .frame(width: 20)
                
                Text(title)
                    .font(VibeCheckTheme.Typography.body)
                    .foregroundColor(VibeCheckTheme.Colors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
            }
            .padding(.horizontal, VibeCheckTheme.Spacing.md)
            .padding(.vertical, VibeCheckTheme.Spacing.sm)
            .background(isHovered ? VibeCheckTheme.Colors.surfaceElevated : Color.clear)
            .cornerRadius(VibeCheckTheme.CornerRadius.sm)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
