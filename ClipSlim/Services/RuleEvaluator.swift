import Foundation

final class RuleEvaluator: Sendable {
    static let shared = RuleEvaluator()
    private init() {}

    struct FileContext: Sendable {
        let fileSize: Int
        let format: ImageFormat
        let fileName: String
        let hasAlpha: Bool
        let width: Int
        let height: Int
    }

    func evaluate(rules: [FolderRule], context: FileContext) -> RuleAction? {
        for rule in rules where rule.isEnabled {
            if matches(condition: rule.condition, context: context) {
                return rule.action
            }
        }
        return nil
    }

    private func matches(condition: RuleCondition, context: FileContext) -> Bool {
        switch condition {
        case .fileSizeGreaterThan(let bytes):
            return context.fileSize > bytes
        case .formatIs(let formatRaw):
            return context.format.rawValue == formatRaw
        case .filenameContains(let text):
            return context.fileName.localizedCaseInsensitiveContains(text)
        case .hasTransparency:
            return context.hasAlpha
        case .dimensionsGreaterThan(let w, let h):
            return context.width > w || context.height > h
        }
    }
}
