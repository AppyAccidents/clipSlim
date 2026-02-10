import SwiftUI

struct VibeSettingsPage<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.md) {
                content
            }
            .padding(VibeCheckTheme.Spacing.lg)
        }
        .font(VibeCheckTheme.Typography.body)
        .foregroundColor(VibeCheckTheme.Colors.textPrimary)
        .tint(VibeCheckTheme.Colors.neonCyan)
        .background(VibeCheckTheme.Colors.background)
    }
}

struct VibeSettingsCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.sm) {
            HStack(spacing: VibeCheckTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(VibeCheckTheme.Colors.neonCyan)
                Text(title)
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.textSecondary)
                    .tracking(1.0)
                Spacer()
            }

            content
                .font(VibeCheckTheme.Typography.body)
                .foregroundColor(VibeCheckTheme.Colors.textPrimary)
        }
        .padding(VibeCheckTheme.Spacing.md)
        .background(VibeCheckTheme.Colors.surface)
        .cornerRadius(VibeCheckTheme.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: VibeCheckTheme.CornerRadius.md)
                .stroke(VibeCheckTheme.Colors.border, lineWidth: 1)
        )
    }
}

struct VibeHintText: View {
    let text: String

    var body: some View {
        Text(text)
            .font(VibeCheckTheme.Typography.caption)
            .foregroundColor(VibeCheckTheme.Colors.textTertiary)
    }
}
