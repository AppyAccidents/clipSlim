import Foundation
import SwiftData

@MainActor
@Observable
final class StatsService {
    private let modelContext: ModelContext
    private let log = Logger.shared

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func recordEvent(
        source: String,
        originalSize: Int,
        optimizedSize: Int,
        format: String,
        duration: Double,
        originalWidth: Int,
        originalHeight: Int,
        optimizedWidth: Int,
        optimizedHeight: Int,
        fileName: String?,
        sourceBundleID: String?,
        contentHash: String?
    ) {
        let event = PersistentOptimizationEvent(
            source: source,
            originalSize: originalSize,
            optimizedSize: optimizedSize,
            format: format,
            duration: duration,
            originalWidth: originalWidth,
            originalHeight: originalHeight,
            optimizedWidth: optimizedWidth,
            optimizedHeight: optimizedHeight,
            fileName: fileName,
            sourceBundleID: sourceBundleID,
            contentHash: contentHash
        )
        modelContext.insert(event)
        try? modelContext.save()
    }

    func totalSaved(since date: Date) -> Int {
        let descriptor = FetchDescriptor<PersistentOptimizationEvent>(
            predicate: #Predicate { $0.timestamp >= date }
        )
        let events = (try? modelContext.fetch(descriptor)) ?? []
        return events.reduce(0) { $0 + ($1.originalSize - $1.optimizedSize) }
    }

    func totalOptimized(since date: Date) -> Int {
        let descriptor = FetchDescriptor<PersistentOptimizationEvent>(
            predicate: #Predicate { $0.timestamp >= date }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    func dailyStats() -> [(date: Date, savedBytes: Int, count: Int)] {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<PersistentOptimizationEvent>(
            predicate: #Predicate { $0.timestamp >= sevenDaysAgo },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        let events = (try? modelContext.fetch(descriptor)) ?? []

        var grouped: [Date: (savedBytes: Int, count: Int)] = [:]
        for event in events {
            let dayStart = calendar.startOfDay(for: event.timestamp)
            let existing = grouped[dayStart] ?? (0, 0)
            grouped[dayStart] = (existing.savedBytes + event.savingsBytes, existing.count + 1)
        }

        return grouped.map { ($0.key, $0.value.savedBytes, $0.value.count) }
            .sorted { $0.date < $1.date }
    }

    func perAppBreakdown() -> [(bundleID: String, savedBytes: Int, count: Int)] {
        let descriptor = FetchDescriptor<PersistentOptimizationEvent>()
        let events = (try? modelContext.fetch(descriptor)) ?? []

        var grouped: [String: (savedBytes: Int, count: Int)] = [:]
        for event in events {
            let key = event.sourceBundleID ?? "Unknown"
            let existing = grouped[key] ?? (0, 0)
            grouped[key] = (existing.savedBytes + event.savingsBytes, existing.count + 1)
        }

        return grouped.map { ($0.key, $0.value.savedBytes, $0.value.count) }
            .sorted { $0.savedBytes > $1.savedBytes }
    }

    func averageCompressionRatio() -> Double {
        let descriptor = FetchDescriptor<PersistentOptimizationEvent>()
        let events = (try? modelContext.fetch(descriptor)) ?? []
        guard !events.isEmpty else { return 0 }
        let totalOriginal = events.reduce(0) { $0 + $1.originalSize }
        let totalOptimized = events.reduce(0) { $0 + $1.optimizedSize }
        guard totalOriginal > 0 else { return 0 }
        return Double(totalOriginal - totalOptimized) / Double(totalOriginal) * 100
    }
}
