import Foundation
import SwiftData

@Model
final class PersistentOptimizationEvent {
    var id: UUID
    var timestamp: Date
    var source: String
    var originalSize: Int
    var optimizedSize: Int
    var format: String
    var duration: Double
    var originalWidth: Int
    var originalHeight: Int
    var optimizedWidth: Int
    var optimizedHeight: Int
    var fileName: String?
    var sourceBundleID: String?
    var contentHash: String?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        source: String,
        originalSize: Int,
        optimizedSize: Int,
        format: String,
        duration: Double,
        originalWidth: Int,
        originalHeight: Int,
        optimizedWidth: Int,
        optimizedHeight: Int,
        fileName: String? = nil,
        sourceBundleID: String? = nil,
        contentHash: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.source = source
        self.originalSize = originalSize
        self.optimizedSize = optimizedSize
        self.format = format
        self.duration = duration
        self.originalWidth = originalWidth
        self.originalHeight = originalHeight
        self.optimizedWidth = optimizedWidth
        self.optimizedHeight = optimizedHeight
        self.fileName = fileName
        self.sourceBundleID = sourceBundleID
        self.contentHash = contentHash
    }

    var savingsBytes: Int {
        originalSize - optimizedSize
    }

    var savingsPercentage: Double {
        guard originalSize > 0 else { return 0 }
        return Double(originalSize - optimizedSize) / Double(originalSize) * 100
    }

    /// Convert from in-memory event
    convenience init(from event: OptimizationEvent, sourceBundleID: String? = nil, contentHash: String? = nil) {
        self.init(
            timestamp: event.timestamp,
            source: event.source.rawValue,
            originalSize: event.result.originalSize,
            optimizedSize: event.result.optimizedSize,
            format: event.result.format.rawValue,
            duration: event.result.duration,
            originalWidth: event.result.originalDimensions.width,
            originalHeight: event.result.originalDimensions.height,
            optimizedWidth: event.result.optimizedDimensions.width,
            optimizedHeight: event.result.optimizedDimensions.height,
            fileName: event.fileName,
            sourceBundleID: sourceBundleID,
            contentHash: contentHash
        )
    }
}
