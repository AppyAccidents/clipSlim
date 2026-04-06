import Foundation
import AppKit
import UniformTypeIdentifiers

class ActionRequestHandler: NSObject, NSExtensionRequestHandling {

    private let supportedTypes: Set<UTType> = [.jpeg, .png, .webP, .heic, .tiff, .bmp]

    func beginRequest(with context: NSExtensionContext) {
        guard let inputItems = context.inputItems as? [NSExtensionItem] else {
            context.cancelRequest(withError: ActionError.noInput)
            return
        }

        Task {
            do {
                var processedCount = 0

                for item in inputItems {
                    guard let attachments = item.attachments else { continue }

                    for attachment in attachments {
                        if let url = try await loadFileURL(from: attachment) {
                            try await processFile(at: url)
                            processedCount += 1
                        }
                    }
                }

                if processedCount == 0 {
                    context.cancelRequest(withError: ActionError.noSupportedFiles)
                } else {
                    context.completeRequest(returningItems: nil)
                }
            } catch {
                context.cancelRequest(withError: error)
            }
        }
    }

    private func loadFileURL(from attachment: NSItemProvider) async throws -> URL? {
        for type in supportedTypes {
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

    private func processFile(at url: URL) async throws {
        let data = try Data(contentsOf: url)

        let config = ImageOptimizer.OptimizationConfig(
            quality: 0.70,
            maxDimension: 1920,
            stripMetadata: true,
            metadataPolicy: .stripAll,
            allowTransparencyLoss: false,
            preferredFormat: .jpeg,
            preserveAlphaByForcingPNG: true
        )

        let (optimizedData, result) = try await ImageOptimizer.shared.optimize(data: data, config: config)

        guard result.savingsPercentage > 1.0 else { return }

        let directory = url.deletingLastPathComponent()
        let baseName = url.deletingPathExtension().lastPathComponent
        let outputExtension = result.format.fileExtension
        let outputURL = directory.appendingPathComponent("\(baseName)_optimized.\(outputExtension)")

        try optimizedData.write(to: outputURL, options: .atomic)
    }
}

enum ActionError: Error, LocalizedError {
    case noInput
    case noSupportedFiles

    var errorDescription: String? {
        switch self {
        case .noInput: return "No input items provided"
        case .noSupportedFiles: return "No supported image files found"
        }
    }
}
