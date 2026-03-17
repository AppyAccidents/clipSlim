import Foundation

enum OptimizationPreset: String, Codable, CaseIterable {
    case highQuality = "High quality"
    case webQuality = "Web quality"
    case compressed = "Compressed"
    case custom = "Custom"
    
    var quality: Double {
        switch self {
        case .highQuality: return 0.85
        case .webQuality: return 0.70
        case .compressed: return 0.50
        case .custom: return 0.72
        }
    }
    
    var maxDimension: Int {
        switch self {
        case .highQuality: return 3840
        case .webQuality: return 1920
        case .compressed: return 1280
        case .custom: return 1920
        }
    }
    
    var stripMetadata: Bool {
        switch self {
        case .highQuality: return false
        case .webQuality: return true
        case .compressed: return true
        case .custom: return true
        }
    }
    
    var allowTransparencyLoss: Bool {
        switch self {
        case .highQuality: return false
        case .webQuality: return true
        case .compressed: return true
        case .custom: return false
        }
    }
}
