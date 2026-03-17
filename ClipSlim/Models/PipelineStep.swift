import Foundation

/// F4: Pipeline steps that can be individually toggled
enum PipelineStep: String, Codable, CaseIterable, Identifiable {
    case resize
    case stripMetadata
    case compress
    case convertFormat

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .resize: return "Resize"
        case .stripMetadata: return "Strip Metadata"
        case .compress: return "Compress"
        case .convertFormat: return "Convert Format"
        }
    }

    var icon: String {
        switch self {
        case .resize: return "arrow.up.left.and.arrow.down.right"
        case .stripMetadata: return "tag.slash"
        case .compress: return "arrow.down.right.and.arrow.up.left"
        case .convertFormat: return "arrow.triangle.2.circlepath"
        }
    }
}
