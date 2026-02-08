import SwiftUI

struct AboutTab: View {
    
    var body: some View {
        VStack(spacing: VibeCheckTheme.Spacing.xl) {
            Spacer()
            
            // App Icon & Name
            VStack(spacing: VibeCheckTheme.Spacing.md) {
                Image(systemName: "scissors")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(VibeCheckTheme.Colors.neonCyan)
                    .neonGlow(color: VibeCheckTheme.Colors.neonCyan, radius: 8)
                
                Text("ClipSlim")
                    .font(VibeCheckTheme.Typography.title)
                    .foregroundColor(VibeCheckTheme.Colors.textPrimary)
                
                Text("v1.0.0")
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
            }
            
            // Description
            VStack(spacing: VibeCheckTheme.Spacing.sm) {
                Text("Automatic clipboard image optimizer")
                    .font(VibeCheckTheme.Typography.body)
                    .foregroundColor(VibeCheckTheme.Colors.textSecondary)
                
                Text("All processing is done locally on your Mac.\nNo data ever leaves your device.")
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
            }
            
            // Tech Stack
            VStack(spacing: VibeCheckTheme.Spacing.sm) {
                infoPill("macOS 14+", icon: "desktopcomputer")
                infoPill("Swift + SwiftUI", icon: "swift")
                infoPill("ImageIO + CoreGraphics", icon: "photo")
                infoPill("No third-party dependencies", icon: "lock.shield")
            }
            .padding(.horizontal, VibeCheckTheme.Spacing.xxl)
            
            Spacer()
            
            Text("© 2026 AppyAccidents")
                .font(VibeCheckTheme.Typography.tiny)
                .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                .padding(.bottom, VibeCheckTheme.Spacing.md)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func infoPill(_ text: String, icon: String) -> some View {
        HStack(spacing: VibeCheckTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(VibeCheckTheme.Colors.neonCyan)
                .frame(width: 20)
            
            Text(text)
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(VibeCheckTheme.Colors.textSecondary)
            
            Spacer()
        }
        .padding(.horizontal, VibeCheckTheme.Spacing.md)
        .padding(.vertical, VibeCheckTheme.Spacing.sm)
        .background(VibeCheckTheme.Colors.surface)
        .cornerRadius(VibeCheckTheme.CornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: VibeCheckTheme.CornerRadius.sm)
                .stroke(VibeCheckTheme.Colors.border, lineWidth: 1)
        )
    }
}
