import SwiftUI
import SwiftData

struct ClipboardHistoryView: View {
    @Query(sort: \ClipboardHistoryEntry.timestamp, order: .reverse)
    private var entries: [ClipboardHistoryEntry]

    @Environment(\.dismiss) private var dismiss

    var onRestoreOriginal: ((ClipboardHistoryEntry) -> Void)?
    var onRestoreOptimized: ((ClipboardHistoryEntry) -> Void)?
    var onClearAll: (() -> Void)?

    @State private var showClearConfirmation = false
    @State private var selectedEntryID: UUID?
    @State private var searchText: String = ""
    @FocusState private var searchFieldFocused: Bool

    private let columns = [
        GridItem(.adaptive(minimum: 120, maximum: 160), spacing: 8)
    ]

    private var filteredEntries: [ClipboardHistoryEntry] {
        guard !searchText.isEmpty else { return entries }
        return entries.filter { entry in
            entry.format.localizedCaseInsensitiveContains(searchText) ||
            entry.formattedOriginalSize.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerBar

            if entries.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(filteredEntries) { entry in
                            historyCard(entry)
                        }
                    }
                    .padding(.horizontal, VibeCheckTheme.Spacing.lg)
                    .padding(.vertical, VibeCheckTheme.Spacing.md)
                }
            }
        }
        .frame(width: 520, height: 440)
        .background(VibeCheckTheme.Colors.background)
        .onKeyPress(keys: [.init("f")], phases: .down) { press in
            if press.modifiers.contains(.command) {
                searchFieldFocused = true
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.escape) {
            dismiss()
            return .handled
        }
        .onKeyPress(keys: [.return], phases: .down) { press in
            guard let selectedID = selectedEntryID,
                  let entry = filteredEntries.first(where: { $0.id == selectedID }) else {
                return .ignored
            }
            if press.modifiers.contains(.shift) {
                onRestoreOriginal?(entry)
            } else {
                onRestoreOptimized?(entry)
            }
            return .handled
        }
        .onKeyPress(.upArrow) {
            navigateSelection(direction: -1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            navigateSelection(direction: 1)
            return .handled
        }
        .alert("Clear History?", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                onClearAll?()
            }
        } message: {
            Text("This will remove all clipboard history entries and their saved files. This cannot be undone.")
        }
    }

    private var headerBar: some View {
        VStack(spacing: VibeCheckTheme.Spacing.xs) {
            HStack {
                Text("Clipboard History")
                    .font(VibeCheckTheme.Typography.headline)
                    .foregroundColor(VibeCheckTheme.Colors.textPrimary)

                Spacer()

                Text("\(filteredEntries.count) items")
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)

                if !entries.isEmpty {
                    Button {
                        showClearConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundColor(VibeCheckTheme.Colors.warning)
                    }
                    .buttonStyle(.plain)
                    .help("Clear all history")
                }
            }

            TextField("Search...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .font(VibeCheckTheme.Typography.caption)
                .focused($searchFieldFocused)
        }
        .padding(.horizontal, VibeCheckTheme.Spacing.lg)
        .padding(.top, VibeCheckTheme.Spacing.md)
        .padding(.bottom, VibeCheckTheme.Spacing.sm)
    }

    private var emptyState: some View {
        VStack(spacing: VibeCheckTheme.Spacing.md) {
            Spacer()
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(VibeCheckTheme.Colors.textTertiary)
            Text("No clipboard history yet")
                .font(VibeCheckTheme.Typography.body)
                .foregroundColor(VibeCheckTheme.Colors.textTertiary)
            Text("Optimized images will appear here")
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(VibeCheckTheme.Colors.textTertiary.opacity(0.7))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func historyCard(_ entry: ClipboardHistoryEntry) -> some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
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

                Text(entry.format)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(VibeCheckTheme.Colors.neonCyan.opacity(0.8))
                    .cornerRadius(3)
                    .padding(4)
            }

            Text(String(format: "%.0f%% saved", entry.savingsPercentage))
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(VibeCheckTheme.Colors.statusOk)

            Text("\(entry.formattedOriginalSize) \u{2192} \(entry.formattedOptimizedSize)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                .lineLimit(1)

            Text(entry.timestamp, style: .relative)
                .font(.system(size: 9))
                .foregroundColor(VibeCheckTheme.Colors.textTertiary.opacity(0.7))

            HStack(spacing: 6) {
                Button {
                    onRestoreOriginal?(entry)
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 9))
                        Text("Orig")
                            .font(.system(size: 9))
                    }
                }
                .buttonStyle(.borderless)
                .help("Copy original to clipboard")

                Button {
                    onRestoreOptimized?(entry)
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 9))
                        Text("Opt")
                            .font(.system(size: 9))
                    }
                }
                .buttonStyle(.borderless)
                .help("Copy optimized to clipboard")
            }
        }
        .padding(8)
        .background(VibeCheckTheme.Colors.surface)
        .cornerRadius(VibeCheckTheme.CornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: VibeCheckTheme.CornerRadius.sm)
                .stroke(
                    entry.id == selectedEntryID
                        ? VibeCheckTheme.Colors.neonCyan
                        : Color.clear,
                    lineWidth: 2
                )
        )
        .onTapGesture {
            selectedEntryID = entry.id
        }
    }

    private func navigateSelection(direction: Int) {
        let list = filteredEntries
        guard !list.isEmpty else { return }

        if let currentID = selectedEntryID,
           let currentIndex = list.firstIndex(where: { $0.id == currentID }) {
            let newIndex = max(0, min(list.count - 1, currentIndex + direction))
            selectedEntryID = list[newIndex].id
        } else {
            selectedEntryID = direction > 0 ? list.first?.id : list.last?.id
        }
    }
}
