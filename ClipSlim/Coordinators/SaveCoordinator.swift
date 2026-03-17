import Foundation
import AppKit

@MainActor
final class SaveCoordinator {

    static let shared = SaveCoordinator()

    private let log = Logger.shared

    private init() {}

    func saveToDisk(
        originalData: Data,
        optimizedData: Data,
        format: ImageFormat,
        fileName: String?,
        sourceURL: URL?,
        settings: AppSettings,
        cropSuffix: String? = nil
    ) async {
        guard settings.saveToDisk else { return }

        let basePath: String
        switch settings.saveDestinationMode {
        case .sameFolder:
            if let sourceURL {
                basePath = sourceURL.deletingLastPathComponent().path
            } else if !settings.saveFolderPath.isEmpty {
                basePath = settings.saveFolderPath
            } else {
                log.app("Skip save: no custom fallback folder for clipboard image in same-folder mode")
                return
            }
        case .customFolder:
            guard !settings.saveFolderPath.isEmpty else {
                log.app("Skip save: custom save folder is not configured")
                return
            }
            basePath = settings.saveFolderPath
        }

        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let baseName = fileName ?? "clipboard-\(timestamp)"
        let nameWithoutExt = sanitizeFilename((baseName as NSString).deletingPathExtension)
        let origExt = (baseName as NSString).pathExtension.isEmpty ? "png" : (baseName as NSString).pathExtension

        let optimizedSuffix: String
        if let suffix = cropSuffix {
            optimizedSuffix = "_optimized_\(suffix)"
        } else {
            optimizedSuffix = "_optimized"
        }

        let originalsPath = (basePath as NSString).appendingPathComponent("Originals")
        let optimizedPathBase = (basePath as NSString).appendingPathComponent("Optimized")

        let originalPath = (originalsPath as NSString).appendingPathComponent("\(nameWithoutExt).\(origExt)")
        let optimizedPath = (optimizedPathBase as NSString).appendingPathComponent("\(nameWithoutExt)\(optimizedSuffix).\(format.fileExtension)")

        do {
            try await Task.detached(priority: .utility) {
                try FileManager.default.createDirectory(atPath: originalsPath, withIntermediateDirectories: true, attributes: nil)
                try FileManager.default.createDirectory(atPath: optimizedPathBase, withIntermediateDirectories: true, attributes: nil)
                try originalData.write(to: URL(fileURLWithPath: originalPath), options: .atomic)
                try optimizedData.write(to: URL(fileURLWithPath: optimizedPath), options: .atomic)
            }.value
            log.app("Saved original/optimized pair to \(basePath)")
        } catch {
            log.error("Failed to save to disk: \(error.localizedDescription)")
        }
    }

    func saveLastPairAs(optimizedData: Data, format: ImageFormat) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose where to save the optimized image"
        panel.prompt = "Save"

        guard panel.runModal() == .OK, let base = panel.url else { return }

        let safeBase = safeFilenameBase(defaultName: "clipslim")
        let optimizedURL = base.appendingPathComponent("\(safeBase)_optimized.\(format.fileExtension)")

        Task {
            do {
                try await Task.detached(priority: .utility) {
                    try optimizedData.write(to: optimizedURL, options: .atomic)
                }.value
                log.app("Saved optimized image via Save As")
            } catch {
                log.error("Save As failed: \(error.localizedDescription)")
            }
        }
    }

    func sanitizeFilename(_ raw: String) -> String {
        let invalid = CharacterSet(charactersIn: "\\/:*?\"<>|")
        let cleaned = raw.components(separatedBy: invalid).joined(separator: "-")
        return cleaned.isEmpty ? "clipslim" : cleaned
    }

    func safeFilenameBase(defaultName: String) -> String {
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        return sanitizeFilename("\(defaultName)-\(timestamp)")
    }
}
