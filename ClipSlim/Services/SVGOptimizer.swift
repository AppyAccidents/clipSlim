import Foundation

struct SVGOptimizationResult: Sendable {
    let originalSize: Int
    let optimizedSize: Int
    let elementsRemoved: Int
    let commentsRemoved: Int
    let processingTime: TimeInterval

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
}

enum SVGOptimizationError: Error, LocalizedError {
    case invalidSVGData
    case parsingFailed(String)
    case serializationFailed

    var errorDescription: String? {
        switch self {
        case .invalidSVGData: return "Invalid SVG data"
        case .parsingFailed(let reason): return "SVG parsing failed: \(reason)"
        case .serializationFailed: return "Failed to serialize optimized SVG"
        }
    }
}

final class SVGOptimizer: Sendable {

    static let shared = SVGOptimizer()

    private init() {}

    /// Editor namespace prefixes to strip
    private static let editorPrefixes: Set<String> = [
        "inkscape", "sodipodi", "dc", "cc", "rdf", "ns0"
    ]

    /// Editor namespace URIs to strip
    private static let editorNamespaceURIs: Set<String> = [
        "http://www.inkscape.org/namespaces/inkscape",
        "http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd",
        "http://purl.org/dc/elements/1.1/",
        "http://creativecommons.org/ns#",
        "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    ]

    func optimize(data: Data) async throws -> (data: Data, result: SVGOptimizationResult) {
        let startTime = CFAbsoluteTimeGetCurrent()

        guard let svgString = String(data: data, encoding: .utf8) else {
            throw SVGOptimizationError.invalidSVGData
        }

        // Verify it looks like SVG
        let trimmed = svgString.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard trimmed.hasPrefix("<?xml") || trimmed.hasPrefix("<svg") else {
            throw SVGOptimizationError.invalidSVGData
        }

        var optimized = svgString
        var elementsRemoved = 0
        var commentsRemoved = 0

        // Step 1: Strip XML comments
        let commentResult = stripComments(optimized)
        optimized = commentResult.result
        commentsRemoved = commentResult.count

        // Step 2: Strip <metadata> elements
        let metadataResult = stripElement(optimized, elementName: "metadata")
        optimized = metadataResult.result
        elementsRemoved += metadataResult.count

        // Step 3: Strip editor namespaces and their elements/attributes
        let nsResult = stripEditorNamespaces(optimized)
        optimized = nsResult.result
        elementsRemoved += nsResult.elementsRemoved

        // Step 4: Remove empty <g> elements
        let emptyGResult = stripEmptyGroups(optimized)
        optimized = emptyGResult.result
        elementsRemoved += emptyGResult.count

        // Step 5: Round numeric attributes to 2 decimal places
        optimized = roundNumericAttributes(optimized)

        // Step 6: Collapse whitespace in path d="" attributes
        optimized = collapsePathWhitespace(optimized)

        // Step 7: Collapse excessive whitespace between tags
        optimized = collapseInterTagWhitespace(optimized)

        guard let outputData = optimized.data(using: .utf8) else {
            throw SVGOptimizationError.serializationFailed
        }

        let processingTime = CFAbsoluteTimeGetCurrent() - startTime

        let result = SVGOptimizationResult(
            originalSize: data.count,
            optimizedSize: outputData.count,
            elementsRemoved: elementsRemoved,
            commentsRemoved: commentsRemoved,
            processingTime: processingTime
        )

        return (outputData, result)
    }

    // MARK: - Transformations

    /// Strip XML comments <!-- ... -->
    private func stripComments(_ input: String) -> (result: String, count: Int) {
        var count = 0
        let pattern = "<!--[\\s\\S]*?-->"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return (input, 0)
        }
        let range = NSRange(input.startIndex..., in: input)
        count = regex.numberOfMatches(in: input, options: [], range: range)
        let result = regex.stringByReplacingMatches(in: input, options: [], range: range, withTemplate: "")
        return (result, count)
    }

    /// Strip a named element and all its contents
    private func stripElement(_ input: String, elementName: String) -> (result: String, count: Int) {
        var count = 0
        // Match both self-closing and open/close elements
        let selfClosingPattern = "<\(elementName)[^>]*/>"
        let openClosePattern = "<\(elementName)[^>]*>[\\s\\S]*?</\(elementName)>"

        var result = input

        if let regex = try? NSRegularExpression(pattern: openClosePattern, options: .caseInsensitive) {
            let range = NSRange(result.startIndex..., in: result)
            count += regex.numberOfMatches(in: result, options: [], range: range)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
        }

        if let regex = try? NSRegularExpression(pattern: selfClosingPattern, options: .caseInsensitive) {
            let range = NSRange(result.startIndex..., in: result)
            count += regex.numberOfMatches(in: result, options: [], range: range)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
        }

        return (result, count)
    }

    /// Strip editor namespace declarations and all elements/attributes using those prefixes
    private func stripEditorNamespaces(_ input: String) -> (result: String, elementsRemoved: Int) {
        var result = input
        var elementsRemoved = 0

        for prefix in Self.editorPrefixes {
            // Remove elements with editor prefix: <prefix:anything ...>...</prefix:anything> and <prefix:anything .../>
            let openClosePattern = "<\(prefix):[a-zA-Z][^>]*>[\\s\\S]*?</\(prefix):[a-zA-Z][^>]*>"
            let selfClosingPattern = "<\(prefix):[a-zA-Z][^>]*/>"

            for pattern in [openClosePattern, selfClosingPattern] {
                if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                    let range = NSRange(result.startIndex..., in: result)
                    elementsRemoved += regex.numberOfMatches(in: result, options: [], range: range)
                    result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
                }
            }

            // Remove attributes with editor prefix: prefix:attr="value"
            let attrPattern = "\\s+\(prefix):[a-zA-Z][a-zA-Z0-9_-]*=\"[^\"]*\""
            if let regex = try? NSRegularExpression(pattern: attrPattern, options: []) {
                let range = NSRange(result.startIndex..., in: result)
                result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
            }

            // Remove xmlns:prefix declarations
            let xmlnsPattern = "\\s+xmlns:\(prefix)=\"[^\"]*\""
            if let regex = try? NSRegularExpression(pattern: xmlnsPattern, options: []) {
                let range = NSRange(result.startIndex..., in: result)
                result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
            }
        }

        return (result, elementsRemoved)
    }

    /// Remove empty <g> elements (no children, or only whitespace)
    private func stripEmptyGroups(_ input: String) -> (result: String, count: Int) {
        let pattern = "<g[^>]*>\\s*</g>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return (input, 0)
        }

        var result = input
        var totalCount = 0

        // Repeat to handle nested empty groups
        var previousLength = 0
        while result.count != previousLength {
            previousLength = result.count
            let range = NSRange(result.startIndex..., in: result)
            let count = regex.numberOfMatches(in: result, options: [], range: range)
            totalCount += count
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
        }

        return (result, totalCount)
    }

    /// Round numeric values in attributes to 2 decimal places
    private func roundNumericAttributes(_ input: String) -> String {
        // Match numeric attribute values like attr="123.456789"
        let pattern = "((?:x|y|width|height|cx|cy|r|rx|ry|x1|y1|x2|y2|dx|dy|font-size|stroke-width)=\")([-]?\\d+\\.\\d{3,})(\")"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return input
        }

        let nsInput = input as NSString
        let range = NSRange(location: 0, length: nsInput.length)
        var result = input

        let matches = regex.matches(in: input, options: [], range: range).reversed()
        for match in matches {
            guard match.numberOfRanges == 4 else { continue }
            let prefixRange = Range(match.range(at: 1), in: input)!
            let numRange = Range(match.range(at: 2), in: input)!
            let suffixRange = Range(match.range(at: 3), in: input)!

            let numStr = String(input[numRange])
            if let value = Double(numStr) {
                let rounded = String(format: "%.2f", value)
                let replacement = String(input[prefixRange]) + rounded + String(input[suffixRange])
                let fullRange = Range(match.range(at: 0), in: result)!
                result = result.replacingCharacters(in: fullRange, with: replacement)
            }
        }

        return result
    }

    /// Collapse whitespace inside path d="" attributes
    private func collapsePathWhitespace(_ input: String) -> String {
        let pattern = "(\\sd=\")([^\"]+)(\")"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return input
        }

        let range = NSRange(input.startIndex..., in: input)
        let matches = regex.matches(in: input, options: [], range: range).reversed()

        var result = input
        for match in matches {
            guard match.numberOfRanges == 4 else { continue }
            let pathRange = Range(match.range(at: 2), in: result)!
            let pathData = String(result[pathRange])

            // Collapse multiple spaces/newlines to single space
            let collapsed = pathData
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)

            result = result.replacingCharacters(in: pathRange, with: collapsed)
        }

        return result
    }

    /// Collapse excessive whitespace between tags
    private func collapseInterTagWhitespace(_ input: String) -> String {
        // Replace multiple newlines/spaces between tags with single newline
        let pattern = ">\\s{2,}<"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return input
        }
        let range = NSRange(input.startIndex..., in: input)
        return regex.stringByReplacingMatches(in: input, options: [], range: range, withTemplate: "> <")
    }
}
