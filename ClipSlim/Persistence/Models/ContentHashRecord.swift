import Foundation
import SwiftData

@Model
final class ContentHashRecord {
    @Attribute(.unique) var contentHash: String
    var id: UUID
    var firstSeenAt: Date
    var lastSeenAt: Date
    var optimizedFileURL: String?
    var optimizedSize: Int

    init(
        contentHash: String,
        id: UUID = UUID(),
        firstSeenAt: Date = Date(),
        lastSeenAt: Date = Date(),
        optimizedFileURL: String? = nil,
        optimizedSize: Int = 0
    ) {
        self.contentHash = contentHash
        self.id = id
        self.firstSeenAt = firstSeenAt
        self.lastSeenAt = lastSeenAt
        self.optimizedFileURL = optimizedFileURL
        self.optimizedSize = optimizedSize
    }
}
