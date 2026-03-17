import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @Environment(DropZoneService.self) private var dropZoneService

    @State private var isTargeted = false

    private let acceptedExtensions: Set<String> = ["jpg", "jpeg", "png", "tiff", "tif", "bmp", "heic", "pdf", "webp"]

    var body: some View {
        VStack(spacing: 0) {
            header
            VibeDivider()
            dropTarget
            if !dropZoneService.dropItems.isEmpty {
                VibeDivider()
                fileList
                VibeDivider()
                summaryFooter
            }
        }
        .frame(minWidth: 320, minHeight: 260)
        .font(VibeCheckTheme.Typography.body)
        .tint(VibeCheckTheme.Colors.neonOrange)
        .background(
            ZStack {
                VibeCheckTheme.Colors.background
                Rectangle().fill(.ultraThinMaterial).opacity(0.3)
            }
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: VibeCheckTheme.Spacing.sm) {
            Image(systemName: "square.and.arrow.down.on.square")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(VibeCheckTheme.Colors.neonCyan)
                .neonGlow(color: VibeCheckTheme.Colors.neonCyan, radius: 4)

            Text("Drop Zone")
                .font(VibeCheckTheme.Typography.title)
                .foregroundColor(VibeCheckTheme.Colors.textPrimary)

            Spacer()

            if dropZoneService.isProcessing {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 16, height: 16)
            }

            Button {
                dropZoneService.hide()
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
        .padding(.horizontal, VibeCheckTheme.Spacing.lg)
        .padding(.vertical, VibeCheckTheme.Spacing.md)
    }

    // MARK: - Drop Target

    private var dropTarget: some View {
        VStack(spacing: VibeCheckTheme.Spacing.md) {
            Image(systemName: isTargeted ? "arrow.down.circle.fill" : "arrow.down.circle.dotted")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(isTargeted ? VibeCheckTheme.Colors.neonCyan : VibeCheckTheme.Colors.textTertiary)
                .if(isTargeted) { view in
                    view.neonGlow(color: VibeCheckTheme.Colors.neonCyan, radius: 8)
                }

            Text("Drop images or PDFs here")
                .font(VibeCheckTheme.Typography.headline)
                .foregroundColor(isTargeted ? VibeCheckTheme.Colors.neonCyan : VibeCheckTheme.Colors.textSecondary)

            Text("JPG, PNG, TIFF, BMP, HEIC, PDF")
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(VibeCheckTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: VibeCheckTheme.CornerRadius.lg)
                .strokeBorder(
                    isTargeted ? VibeCheckTheme.Colors.neonCyan : VibeCheckTheme.Colors.border,
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
                .background(
                    isTargeted
                        ? VibeCheckTheme.Colors.neonCyan.opacity(0.05)
                        : Color.clear
                )
        )
        .cornerRadius(VibeCheckTheme.CornerRadius.lg)
        .padding(.horizontal, VibeCheckTheme.Spacing.lg)
        .padding(.vertical, VibeCheckTheme.Spacing.md)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
            return true
        }
    }

    // MARK: - File List

    private var fileList: some View {
        ScrollView {
            LazyVStack(spacing: VibeCheckTheme.Spacing.xs) {
                ForEach(dropZoneService.dropItems) { item in
                    fileRow(item)
                }
            }
            .padding(.horizontal, VibeCheckTheme.Spacing.lg)
            .padding(.vertical, VibeCheckTheme.Spacing.sm)
        }
        .frame(maxHeight: 200)
    }

    private func fileRow(_ item: DropItem) -> some View {
        HStack(spacing: VibeCheckTheme.Spacing.sm) {
            statusIcon(item.state)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.fileName)
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.textPrimary)
                    .lineLimit(1)

                statusText(item)
            }

            Spacer()
        }
        .padding(.horizontal, VibeCheckTheme.Spacing.sm)
        .padding(.vertical, VibeCheckTheme.Spacing.xs)
        .background(VibeCheckTheme.Colors.surface)
        .cornerRadius(VibeCheckTheme.CornerRadius.sm)
    }

    private func statusIcon(_ state: DropItem.State) -> some View {
        Group {
            switch state {
            case .pending:
                Image(systemName: "clock")
                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
            case .processing:
                ProgressView()
                    .scaleEffect(0.5)
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(VibeCheckTheme.Colors.success)
            case .failed:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(VibeCheckTheme.Colors.error)
            }
        }
        .font(.system(size: 12))
        .frame(width: 16, height: 16)
    }

    private func statusText(_ item: DropItem) -> some View {
        Group {
            switch item.state {
            case .pending:
                Text("Waiting…")
                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
            case .processing:
                Text("Optimizing…")
                    .foregroundColor(VibeCheckTheme.Colors.neonCyan)
            case .completed(let savedBytes, let percent):
                let savedStr = ByteCountFormatter.string(fromByteCount: Int64(savedBytes), countStyle: .file)
                Text("\(String(format: "%.1f%%", percent)) saved (\(savedStr))")
                    .foregroundColor(VibeCheckTheme.Colors.success)
            case .failed(let message):
                Text(message)
                    .foregroundColor(VibeCheckTheme.Colors.error)
            }
        }
        .font(VibeCheckTheme.Typography.tiny)
    }

    // MARK: - Summary Footer

    private var summaryFooter: some View {
        HStack {
            Text("\(dropZoneService.dropItems.count) file\(dropZoneService.dropItems.count == 1 ? "" : "s")")
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(VibeCheckTheme.Colors.textSecondary)

            Spacer()

            Text("Saved: \(ByteCountFormatter.string(fromByteCount: Int64(dropZoneService.totalSaved), countStyle: .file))")
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(VibeCheckTheme.Colors.success)
        }
        .padding(.horizontal, VibeCheckTheme.Spacing.lg)
        .padding(.vertical, VibeCheckTheme.Spacing.sm)
    }

    // MARK: - Drop Handling

    private func handleDrop(_ providers: [NSItemProvider]) {
        var urls: [URL] = []
        let group = DispatchGroup()

        for provider in providers {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                defer { group.leave() }
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    let ext = url.pathExtension.lowercased()
                    if acceptedExtensions.contains(ext) {
                        urls.append(url)
                    }
                }
            }
        }

        group.notify(queue: .main) {
            guard !urls.isEmpty else { return }
            // F7: Single-item drop → quick action mode
            if urls.count == 1, let singleURL = urls.first {
                if dropZoneService.onSingleFileDropped != nil {
                    dropZoneService.onSingleFileDropped?(singleURL)
                    return
                }
            }
            dropZoneService.onFilesDropped?(urls)
        }
    }
}
