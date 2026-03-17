import Foundation
import SwiftData

@MainActor
final class PersistenceController {

    static let shared = PersistenceController()

    let container: ModelContainer

    private init() {
        let schema = Schema([
            PersistentOptimizationEvent.self,
            ClipboardHistoryEntry.self,
            ContentHashRecord.self,
        ])
        let config = ModelConfiguration(
            "ClipSlimStore",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    /// For unit tests — in-memory store
    static func inMemory() -> ModelContainer {
        let schema = Schema([
            PersistentOptimizationEvent.self,
            ClipboardHistoryEntry.self,
            ContentHashRecord.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create in-memory ModelContainer: \(error)")
        }
    }
}
