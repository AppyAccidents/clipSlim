import Foundation

struct OptimizationEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
    let source: Source
    let result: OptimizationResult
    let fileName: String?
    
    enum Source: String {
        case clipboard = "Clipboard"
        case folder = "Folder"
        case dropZone = "Drop Zone"
    }
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
    
    var summary: String {
        let name = fileName ?? "Image"
        return "\(name): \(result.formattedOriginalSize) → \(result.formattedOptimizedSize) (\(String(format: "%.1f", result.savingsPercentage))%)"
    }
}
