import SwiftUI
import SwiftData

struct ClipboardHistoryView: View {
    @Query(sort: \ClipboardHistoryEntry.timestamp, order: .reverse)
    private var entries: [ClipboardHistoryEntry]

    @Environment(\.dismiss) private var dismiss

    var onRestoreOriginal: ((ClipboardHistoryEntry) -> Void)?
    var onRestoreOptimized: ((ClipboardHistoryEntry) -> Void)?

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 140), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.md) {
            HStack {
                Text("Clipboard History")
                    .font(VibeCheckTheme.Typography.headline)
                    .foregroundColor(VibeCheckTheme.Colors.textPrimary)
                Spacer()
                Text("\(entries.count) items")
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
            }
            .padding(.horizontal, VibeCheckTheme.Spacing.lg)
            .padding(.top, VibeCheckTheme.Spacing.md)

            if entries.isEmpty {
                VStack {
                    Spacer()
                    Text("No clipboard history yet")
                        .font(VibeCheckTheme.Typography.body)
                        .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(entries) { entry in
                            historyCard(entry)
                        }
                    }
                    .padding(.horizontal, VibeCheckTheme.Spacing.lg)
                }
            }
        }
        .frame(width: 480, height: 400)
        .background(VibeCheckTheme.Colors.background)
    }

    private func historyCard(_ entry: ClipboardHistoryEntry) -> some View {
        VStack(spacing: 4) {
            if let thumbData = entry.thumbnailData, let nsImage = NSImage(data: thumbData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)
            } else {
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 80)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                    )
            }

            Text(String(format: "%.0f%%", entry.savingsPercentage))
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(VibeCheckTheme.Colors.statusOk)

            HStack(spacing: 4) {
                Button {
                    onRestoreOriginal?(entry)
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 9))
                }
                .buttonStyle(.borderless)

                Button {
                    onRestoreOptimized?(entry)
                } label: {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 9))
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(6)
        .background(VibeCheckTheme.Colors.surface)
        .cornerRadius(VibeCheckTheme.CornerRadius.sm)
    }
}
