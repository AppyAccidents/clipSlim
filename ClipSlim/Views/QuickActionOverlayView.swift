import SwiftUI

struct QuickActionOverlayView: View {
    let fileName: String
    let fileSize: Int

    var onResize: (() -> Void)?
    var onCompress: (() -> Void)?
    var onConvert: (() -> Void)?
    var onCopy: (() -> Void)?
    var onSave: (() -> Void)?
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(spacing: VibeCheckTheme.Spacing.md) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(VibeCheckTheme.Colors.neonOrange)
                Text("Quick Action")
                    .font(VibeCheckTheme.Typography.headline)
                    .foregroundColor(VibeCheckTheme.Colors.textPrimary)
                Spacer()
                Button {
                    onDismiss?()
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

            VStack(alignment: .leading, spacing: 4) {
                Text(fileName)
                    .font(VibeCheckTheme.Typography.body)
                    .foregroundColor(VibeCheckTheme.Colors.textPrimary)
                    .lineLimit(1)
                Text(ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file))
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                quickButton("Resize", icon: "arrow.up.left.and.arrow.down.right") { onResize?() }
                quickButton("Compress", icon: "arrow.down.right.and.arrow.up.left") { onCompress?() }
                quickButton("Convert", icon: "arrow.triangle.2.circlepath") { onConvert?() }
                quickButton("Copy", icon: "doc.on.doc") { onCopy?() }
            }

            quickButton("Save to Disk", icon: "square.and.arrow.down") { onSave?() }
        }
        .padding(VibeCheckTheme.Spacing.lg)
        .frame(width: 280)
        .background(
            ZStack {
                Color(hex: "111116").opacity(0.92)
                Rectangle().fill(.ultraThinMaterial)
            }
        )
        .cornerRadius(VibeCheckTheme.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: VibeCheckTheme.CornerRadius.lg)
                .stroke(
                    LinearGradient(
                        colors: [VibeCheckTheme.Colors.neonOrange.opacity(0.45), VibeCheckTheme.Colors.neonOrange.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.5), radius: 16, x: 0, y: 6)
    }

    private func quickButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: VibeCheckTheme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(VibeCheckTheme.Typography.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, VibeCheckTheme.Spacing.sm)
            .foregroundColor(VibeCheckTheme.Colors.neonCyan)
            .background(Color.white.opacity(0.07))
            .cornerRadius(VibeCheckTheme.CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: VibeCheckTheme.CornerRadius.sm)
                    .stroke(VibeCheckTheme.Colors.neonCyan.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
