import Foundation

final class SessionLogExporter {
    static let shared = SessionLogExporter()
    private init() {}

    struct ExportableEvent: Codable {
        let timestamp: String
        let source: String
        let originalSize: Int
        let optimizedSize: Int
        let savingsPercentage: Double
        let format: String
        let duration: Double
        let originalDimensions: String
        let optimizedDimensions: String
        let fileName: String?
    }

    func export(events: [OptimizationEvent]) -> Data? {
        let formatter = ISO8601DateFormatter()
        let exportable = events.map { event in
            ExportableEvent(
                timestamp: formatter.string(from: event.timestamp),
                source: event.source.rawValue,
                originalSize: event.result.originalSize,
                optimizedSize: event.result.optimizedSize,
                savingsPercentage: event.result.savingsPercentage,
                format: event.result.format.rawValue,
                duration: event.result.duration,
                originalDimensions: "\(event.result.originalDimensions.width)x\(event.result.originalDimensions.height)",
                optimizedDimensions: "\(event.result.optimizedDimensions.width)x\(event.result.optimizedDimensions.height)",
                fileName: event.fileName
            )
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(exportable)
    }

    func exportToFile(events: [OptimizationEvent], url: URL) throws {
        guard let data = export(events: events) else {
            throw NSError(domain: "SessionLogExporter", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode events"])
        }
        try data.write(to: url, options: .atomic)
    }
}
