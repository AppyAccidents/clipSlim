import Foundation

struct FolderRule: Codable, Identifiable {
    let id: UUID
    var condition: RuleCondition
    var action: RuleAction
    var isEnabled: Bool

    init(id: UUID = UUID(), condition: RuleCondition, action: RuleAction, isEnabled: Bool = true) {
        self.id = id
        self.condition = condition
        self.action = action
        self.isEnabled = isEnabled
    }
}

enum RuleCondition: Codable {
    case fileSizeGreaterThan(bytes: Int)
    case formatIs(String) // ImageFormat rawValue
    case filenameContains(String)
    case hasTransparency
    case dimensionsGreaterThan(width: Int, height: Int)

    var displayName: String {
        switch self {
        case .fileSizeGreaterThan(let bytes):
            return "File size > \(ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file))"
        case .formatIs(let format):
            return "Format is \(format)"
        case .filenameContains(let text):
            return "Filename contains \"\(text)\""
        case .hasTransparency:
            return "Has transparency"
        case .dimensionsGreaterThan(let w, let h):
            return "Dimensions > \(w)x\(h)"
        }
    }
}

enum RuleAction: Codable {
    case compressAggressive
    case convertTo(String) // ImageFormat rawValue
    case keepHighQuality
    case skip
    case customQuality(Double)

    var displayName: String {
        switch self {
        case .compressAggressive: return "Compress aggressively"
        case .convertTo(let format): return "Convert to \(format)"
        case .keepHighQuality: return "Keep high quality"
        case .skip: return "Skip"
        case .customQuality(let q): return "Quality \(Int(q * 100))%"
        }
    }
}
