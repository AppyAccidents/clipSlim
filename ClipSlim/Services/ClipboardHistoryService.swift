import Foundation
import SwiftData
import AppKit
import CoreGraphics
import ImageIO

@MainActor
@Observable
final class ClipboardHistoryService {
    private let modelContext: ModelContext
    private let log = Logger.shared
    private let maxEntries = 50
    private let thumbnailMaxSide = 256

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func addEntry(
        originalData: Data,
        optimizedData: Data,
        originalSize: Int,
        optimizedSize: Int,
        format: ImageFormat,
        sourceBundleID: String?
    ) {
        let thumbnail = generateThumbnail(from: optimizedData)

        let historyDir = Self.historyDirectory()
        let id = UUID()
        let origURL = historyDir.appendingPathComponent("\(id.uuidString)_original.\(format.fileExtension)")
        let optURL = historyDir.appendingPathComponent("\(id.uuidString)_optimized.\(format.fileExtension)")

        do {
            try FileManager.default.createDirectory(at: historyDir, withIntermediateDirectories: true)
            try originalData.write(to: origURL, options: .atomic)
            try optimizedData.write(to: optURL, options: .atomic)
        } catch {
            log.error("Failed to save history files: \(error.localizedDescription)")
            return
        }

        let entry = ClipboardHistoryEntry(
            id: id,
            thumbnailData: thumbnail,
            originalFileURL: origURL.path,
            optimizedFileURL: optURL.path,
            originalSize: originalSize,
            optimizedSize: optimizedSize,
            format: format.rawValue,
            sourceBundleID: sourceBundleID
        )
        modelContext.insert(entry)
        try? modelContext.save()

        cleanup()
    }

    func entries() -> [ClipboardHistoryEntry] {
        let descriptor = FetchDescriptor<ClipboardHistoryEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func restoreOriginal(entry: ClipboardHistoryEntry) {
        guard let path = entry.originalFileURL,
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return }
        let format = ImageFormat(rawValue: entry.format) ?? .png
        let pb = NSPasteboard.general
        pb.clearContents()
        let pbType = NSPasteboard.PasteboardType(format.utType)
        pb.setData(data, forType: pbType)
    }

    func restoreOptimized(entry: ClipboardHistoryEntry) {
        guard let path = entry.optimizedFileURL,
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return }
        let format = ImageFormat(rawValue: entry.format) ?? .png
        let pb = NSPasteboard.general
        pb.clearContents()
        let pbType = NSPasteboard.PasteboardType(format.utType)
        pb.setData(data, forType: pbType)
    }

    private func cleanup() {
        let descriptor = FetchDescriptor<ClipboardHistoryEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        guard let all = try? modelContext.fetch(descriptor), all.count > maxEntries else { return }

        let toRemove = all.suffix(from: maxEntries)
        for entry in toRemove {
            if let path = entry.originalFileURL { try? FileManager.default.removeItem(atPath: path) }
            if let path = entry.optimizedFileURL { try? FileManager.default.removeItem(atPath: path) }
            modelContext.delete(entry)
        }
        try? modelContext.save()
    }

    private func generateThumbnail(from data: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: thumbnailMaxSide,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }

        let mutableData = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(mutableData as CFMutableData, "public.jpeg" as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(dest, thumbnail, [kCGImageDestinationLossyCompressionQuality: 0.6] as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return mutableData as Data
    }

    static func historyDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("ClipSlim/History")
    }
}
