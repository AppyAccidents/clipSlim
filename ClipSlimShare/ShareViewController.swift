import SwiftUI
import AppKit
import UniformTypeIdentifiers

class ShareViewController: NSViewController {

    private let supportedUTTypes: Set<UTType> = [
        .jpeg, .png, .webP, .heic, .tiff, .bmp, .pdf,
        // .movie, .gif, .svg — Spec A additions
    ]

    private let maxFileSize: Int = 100 * 1024 * 1024 // 100 MB

    override func loadView() {
        let hostingView = NSHostingView(
            rootView: ShareExtensionContentView(
                onOptimize: { [weak self] preset in
                    self?.optimize(preset: preset)
                },
                onCancel: { [weak self] in
                    self?.extensionContext?.cancelRequest(withError: ShareError.cancelled)
                }
            )
        )
        self.view = hostingView
        self.preferredContentSize = NSSize(width: 380, height: 300)
    }

    private func optimize(preset: SharePreset) {
        guard let extensionContext = extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            extensionContext?.cancelRequest(withError: ShareError.noInput)
            return
        }

        Task {
            do {
                for item in inputItems {
                    guard let attachments = item.attachments else { continue }
                    for attachment in attachments {
                        if let url = try await loadFileURL(from: attachment) {
                            let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
                            let fileSize = (attrs[.size] as? Int) ?? 0
                            if fileSize > maxFileSize {
                                continue // Skip files > 100MB
                            }
                            try await processFile(at: url, preset: preset)
                        }
                    }
                }
                extensionContext.completeRequest(returningItems: nil)
            } catch {
                extensionContext.cancelRequest(withError: error)
            }
        }
    }

    private func loadFileURL(from attachment: NSItemProvider) async throws -> URL? {
        for type in supportedUTTypes {
            if attachment.hasItemConformingToTypeIdentifier(type.identifier) {
                return try await withCheckedThrowingContinuation { continuation in
                    attachment.loadItem(forTypeIdentifier: type.identifier) { item, error in
                        if let error {
                            continuation.resume(throwing: error)
                        } else if let url = item as? URL {
                            continuation.resume(returning: url)
                        } else {
                            continuation.resume(returning: nil)
                        }
                    }
                }
            }
        }
        return nil
    }

    private func processFile(at url: URL, preset: SharePreset) async throws {
        let data = try Data(contentsOf: url)

        let fileType = OptimizableFileType.from(data: data)
        if case .pdf = fileType {
            let config = PDFOptimizer.PDFOptimizationConfig(
                targetDPI: preset.pdfDPI,
                imageQuality: preset.quality,
                stripMetadata: true
            )
            let (optimizedData, pdfResult) = try PDFOptimizer.shared.optimize(data: data, config: config)
            guard pdfResult.optimizedSize < pdfResult.originalSize else { return }

            let outputURL = url.deletingLastPathComponent()
                .appendingPathComponent(url.deletingPathExtension().lastPathComponent + "_optimized.pdf")
            try optimizedData.write(to: outputURL, options: .atomic)
        } else {
            let config = ImageOptimizer.OptimizationConfig(
                quality: preset.quality,
                maxDimension: preset.maxDimension,
                stripMetadata: true,
                metadataPolicy: .stripAll,
                allowTransparencyLoss: false,
                preferredFormat: preset.format,
                preserveAlphaByForcingPNG: true
            )
            let (optimizedData, result) = try await ImageOptimizer.shared.optimize(data: data, config: config)
            guard result.savingsPercentage > 1.0 else { return }

            let baseName = url.deletingPathExtension().lastPathComponent
            let outputURL = url.deletingLastPathComponent()
                .appendingPathComponent("\(baseName)_optimized.\(result.format.fileExtension)")
            try optimizedData.write(to: outputURL, options: .atomic)
        }
    }
}

enum SharePreset: String, CaseIterable, Identifiable {
    case web
    case high
    case compressed
    case lossless

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .web: return "Web"
        case .high: return "High"
        case .compressed: return "Compressed"
        case .lossless: return "Lossless"
        }
    }

    var quality: Double {
        switch self {
        case .web: return 0.70
        case .high: return 0.85
        case .compressed: return 0.50
        case .lossless: return 1.0
        }
    }

    var maxDimension: Int {
        switch self {
        case .web: return 1920
        case .high: return 4096
        case .compressed: return 1280
        case .lossless: return Int.max
        }
    }

    var format: ImageFormat {
        switch self {
        case .web: return .jpeg
        case .high: return .jpeg
        case .compressed: return .jpeg
        case .lossless: return .png
        }
    }

    var pdfDPI: Int {
        switch self {
        case .web: return 100
        case .high: return 150
        case .compressed: return 72
        case .lossless: return 300
        }
    }
}

enum ShareError: Error, LocalizedError {
    case noInput
    case cancelled

    var errorDescription: String? {
        switch self {
        case .noInput: return "No files to optimize"
        case .cancelled: return "Cancelled"
        }
    }
}

private struct ShareExtensionContentView: View {
    var onOptimize: (SharePreset) -> Void
    var onCancel: () -> Void

    @State private var selectedPreset: SharePreset = .web

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "scissors")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.cyan)
                Text("ClipSlim")
                    .font(.headline)
                Spacer()
            }

            Text("Choose optimization preset:")
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)

            Picker("Preset", selection: $selectedPreset) {
                ForEach(SharePreset.allCases) { preset in
                    Text(preset.displayName).tag(preset)
                }
            }
            .pickerStyle(.segmented)

            Text(presetDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Optimize") {
                    onOptimize(selectedPreset)
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
        }
        .padding(20)
        .frame(width: 380, height: 300)
    }

    private var presetDescription: String {
        switch selectedPreset {
        case .web: return "Quality 70%, max 1920px. Best for web and email."
        case .high: return "Quality 85%, max 4096px. Balanced quality and size."
        case .compressed: return "Quality 50%, max 1280px. Maximum compression."
        case .lossless: return "Quality 100%, original size. No quality loss."
        }
    }
}
