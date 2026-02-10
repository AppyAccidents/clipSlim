import Foundation

struct RuleEvaluationContext {
    let frontmostBundleID: String
    let byteSize: Int
    let dimensions: (width: Int, height: Int)
    let hasAlpha: Bool
}

struct RuleDecision {
    var shouldOptimize: Bool = true
    var presetOverride: OptimizationPreset?
    var formatOverride: ImageFormat?
    var matchedRuleName: String?
}

struct RuleEngine {
    func evaluate(rules: [OptimizationRule], context: RuleEvaluationContext) -> RuleDecision {
        for rule in rules where rule.enabled {
            guard matches(rule: rule, context: context) else { continue }
            return RuleDecision(
                shouldOptimize: !rule.shouldSkip,
                presetOverride: rule.overridePreset,
                formatOverride: rule.overrideFormat,
                matchedRuleName: rule.name
            )
        }
        return RuleDecision()
    }

    private func matches(rule: OptimizationRule, context: RuleEvaluationContext) -> Bool {
        if !rule.frontmostBundleID.isEmpty && rule.frontmostBundleID != context.frontmostBundleID {
            return false
        }

        if rule.minBytes > 0 && context.byteSize < rule.minBytes {
            return false
        }

        if rule.maxBytes > 0 && context.byteSize > rule.maxBytes {
            return false
        }

        let largestDimension = max(context.dimensions.width, context.dimensions.height)
        if rule.minDimension > 0 && largestDimension < rule.minDimension {
            return false
        }

        if rule.maxDimension > 0 && largestDimension > rule.maxDimension {
            return false
        }

        switch rule.transparencyCondition {
        case .any:
            break
        case .transparent:
            if !context.hasAlpha { return false }
        case .opaque:
            if context.hasAlpha { return false }
        }

        return true
    }
}
