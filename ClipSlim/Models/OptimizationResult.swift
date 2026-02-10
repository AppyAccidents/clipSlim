import Foundation

struct OptimizationResult {
    let originalSize: Int
    let optimizedSize: Int
    let format: ImageFormat
    let duration: TimeInterval
    let originalDimensions: (width: Int, height: Int)
    let optimizedDimensions: (width: Int, height: Int)
    
    var savingsPercentage: Double {
        guard originalSize > 0 else { return 0 }
        return Double(originalSize - optimizedSize) / Double(originalSize) * 100
    }
    
    var savingsBytes: Int {
        return originalSize - optimizedSize
    }
    
    var formattedOriginalSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(originalSize), countStyle: .file)
    }
    
    var formattedOptimizedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(optimizedSize), countStyle: .file)
    }
    
    var formattedSavings: String {
        ByteCountFormatter.string(fromByteCount: Int64(savingsBytes), countStyle: .file)
    }

    var preciseOriginalSize: String {
        Self.preciseSizeString(bytes: originalSize)
    }

    var preciseOptimizedSize: String {
        Self.preciseSizeString(bytes: optimizedSize)
    }

    private static func preciseSizeString(bytes: Int) -> String {
        let value = Double(bytes)
        if bytes < 1024 {
            return "\(bytes) B"
        }
        if bytes < 1024 * 1024 {
            return String(format: "%.2f KB", value / 1024.0)
        }
        if bytes < 1024 * 1024 * 1024 {
            return String(format: "%.2f MB", value / (1024.0 * 1024.0))
        }
        return String(format: "%.2f GB", value / (1024.0 * 1024.0 * 1024.0))
    }
}
