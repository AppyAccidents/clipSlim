import Foundation
import SwiftData

/// F6: Cross-session duplicate detection backed by SwiftData ContentHashRecord
@MainActor
@Observable
final class DuplicateHashService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func findRecord(hash: String) -> ContentHashRecord? {
        var descriptor = FetchDescriptor<ContentHashRecord>(
            predicate: #Predicate { $0.contentHash == hash }
        )
        descriptor.fetchLimit = 1
        return (try? modelContext.fetch(descriptor))?.first
    }

    func recordHash(_ hash: String, optimizedSize: Int, optimizedFileURL: String? = nil) {
        let record = ContentHashRecord(
            contentHash: hash,
            optimizedFileURL: optimizedFileURL,
            optimizedSize: optimizedSize
        )
        modelContext.insert(record)
        try? modelContext.save()
    }

    func touchRecord(_ record: ContentHashRecord) {
        record.lastSeenAt = Date()
        try? modelContext.save()
    }
}
