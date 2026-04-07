import Foundation

enum BatchRenamer {

    /// Applies a rename template to produce a filename (without extension).
    /// Extension is appended separately by the caller.
    ///
    /// Supported tokens: {name}, {ext}, {date}, {time}, {n}, {width}, {height}, {format}, {preset}, {savings}
    /// Unknown tokens are left as literal text (no crash on typos).
    static func rename(template: String, context: RenameContext) -> String {
        let tokens: [String: String] = [
            "name": context.originalName,
            "ext": context.outputExtension,
            "date": context.dateString,
            "time": context.timeString,
            "n": context.paddedNumber,
            "width": "\(context.width)",
            "height": "\(context.height)",
            "format": context.formatName,
            "preset": context.presetName,
            "savings": "\(context.savingsPercent)",
        ]

        var result = ""
        var index = template.startIndex

        while index < template.endIndex {
            if template[index] == "{" {
                // Look for closing brace
                let afterBrace = template.index(after: index)
                if let closingIndex = template[afterBrace...].firstIndex(of: "}") {
                    let tokenName = String(template[afterBrace..<closingIndex])
                    if let replacement = tokens[tokenName] {
                        result += replacement
                    } else {
                        // Unknown token — leave as literal
                        result += "{\(tokenName)}"
                    }
                    index = template.index(after: closingIndex)
                } else {
                    // No closing brace — treat as literal
                    result.append(template[index])
                    index = template.index(after: index)
                }
            } else {
                result.append(template[index])
                index = template.index(after: index)
            }
        }

        return result
    }

    /// Generates a preview string with example values.
    static func preview(template: String) -> String {
        let context = RenameContext(
            originalName: "hero",
            outputExtension: "webp",
            date: Date(),
            sequenceNumber: 1,
            width: 1920,
            height: 1080,
            formatName: "webp",
            presetName: "Web quality",
            savingsPercent: 42
        )
        return rename(template: template, context: context) + "." + context.outputExtension
    }
}
