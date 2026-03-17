import Foundation
import SwiftData

@Model
final class ClipboardHistoryEntry {
    var id: UUID
    var timestamp: Date
    var thumbnailData: Data?
    var originalFileURL: String?
    var optimizedFileURL: String?
    var originalSize: Int
    var optimizedSize: Int
    var format: String
    var sourceBundleID: String?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        thumbnailData: Data? = nil,
        originalFileURL: String? = nil,
        optimizedFileURL: String? = nil,
        originalSize: Int = 0,
        optimizedSize: Int = 0,
        format: String = "JPEG",
        sourceBundleID: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.thumbnailData = thumbnailData
        self.originalFileURL = originalFileURL
        self.optimizedFileURL = optimizedFileURL
        self.originalSize = originalSize
        self.optimizedSize = optimizedSize
        self.format = format
        self.sourceBundleID = sourceBundleID
    }

    var savingsPercentage: Double {
        guard originalSize > 0 else { return 0 }
        return Double(originalSize - optimizedSize) / Double(originalSize) * 100
    }

    var formattedOriginalSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(originalSize), countStyle: .file)
    }

    var formattedOptimizedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(optimizedSize), countStyle: .file)
    }
}
