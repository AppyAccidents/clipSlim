import Foundation

enum OptimizationPreset: String, Codable, CaseIterable {
    case web = "Web"
    case highQuality = "High Quality"
    case small = "Small"
    case custom = "Custom"
    
    var quality: Double {
        switch self {
        case .web: return 0.75
        case .highQuality: return 0.90
        case .small: return 0.60
        case .custom: return 0.75
        }
    }
    
    var maxDimension: Int {
        switch self {
        case .web: return 1920
        case .highQuality: return 3840
        case .small: return 1280
        case .custom: return 1920
        }
    }
    
    var stripMetadata: Bool {
        switch self {
        case .web: return true
        case .highQuality: return false
        case .small: return true
        case .custom: return true
        }
    }
    
    var allowTransparencyLoss: Bool {
        switch self {
        case .web: return true
        case .highQuality: return false
        case .small: return true
        case .custom: return false
        }
    }
}
