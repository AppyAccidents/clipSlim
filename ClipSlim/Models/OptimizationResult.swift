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
}
