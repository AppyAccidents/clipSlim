import XCTest
@testable import ClipSlim

final class SVGOptimizerTests: XCTestCase {

    let optimizer = SVGOptimizer.shared

    // MARK: - Comment Stripping

    func testStripComments() async throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
        <!-- This is a comment -->
        <rect x="0" y="0" width="100" height="100" fill="red"/>
        <!-- Another comment -->
        </svg>
        """
        let data = Data(svg.utf8)
        let (outputData, result) = try await optimizer.optimize(data: data)
        let output = String(data: outputData, encoding: .utf8)!

        XCTAssertFalse(output.contains("<!--"))
        XCTAssertEqual(result.commentsRemoved, 2)
        XCTAssertTrue(output.contains("<rect"))
    }

    // MARK: - Metadata Stripping

    func testStripMetadata() async throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
        <metadata>
            <rdf:RDF>
                <cc:Work>
                    <dc:title>Test</dc:title>
                </cc:Work>
            </rdf:RDF>
        </metadata>
        <rect x="0" y="0" width="100" height="100" fill="blue"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let (outputData, result) = try await optimizer.optimize(data: data)
        let output = String(data: outputData, encoding: .utf8)!

        XCTAssertFalse(output.contains("<metadata"))
        XCTAssertFalse(output.contains("</metadata>"))
        XCTAssertGreaterThan(result.elementsRemoved, 0)
        XCTAssertTrue(output.contains("<rect"))
    }

    // MARK: - Editor Namespace Stripping

    func testStripInkscapeNamespace() async throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" viewBox="0 0 100 100">
        <g inkscape:groupmode="layer" inkscape:label="Layer 1">
            <rect x="0" y="0" width="100" height="100" fill="green"/>
        </g>
        <sodipodi:namedview inkscape:zoom="1"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let (outputData, _) = try await optimizer.optimize(data: data)
        let output = String(data: outputData, encoding: .utf8)!

        XCTAssertFalse(output.contains("inkscape:"))
        XCTAssertFalse(output.contains("sodipodi:"))
        XCTAssertFalse(output.contains("xmlns:inkscape"))
        XCTAssertTrue(output.contains("<rect"))
    }

    func testStripSodipodiNamespace() async throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd" viewBox="0 0 100 100">
        <sodipodi:namedview pagecolor="#ffffff"/>
        <rect x="0" y="0" width="100" height="100" fill="red"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let (outputData, _) = try await optimizer.optimize(data: data)
        let output = String(data: outputData, encoding: .utf8)!

        XCTAssertFalse(output.contains("sodipodi"))
    }

    // MARK: - Empty Group Removal

    func testStripEmptyGroups() async throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
        <g></g>
        <g>  </g>
        <g><rect x="0" y="0" width="50" height="50" fill="red"/></g>
        </svg>
        """
        let data = Data(svg.utf8)
        let (outputData, result) = try await optimizer.optimize(data: data)
        let output = String(data: outputData, encoding: .utf8)!

        // Two empty groups should be removed
        XCTAssertGreaterThanOrEqual(result.elementsRemoved, 2)
        // Non-empty group should remain
        XCTAssertTrue(output.contains("<rect"))
    }

    // MARK: - Numeric Rounding

    func testRoundNumericAttributes() async throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
        <rect x="10.123456" y="20.987654" width="50.111111" height="30.999999" fill="red"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let (outputData, _) = try await optimizer.optimize(data: data)
        let output = String(data: outputData, encoding: .utf8)!

        XCTAssertTrue(output.contains("x=\"10.12\""))
        XCTAssertTrue(output.contains("y=\"20.99\""))
        XCTAssertTrue(output.contains("width=\"50.11\""))
        XCTAssertTrue(output.contains("height=\"31.00\""))
    }

    func testDoesNotRoundShortDecimals() async throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
        <rect x="10.5" y="20" width="50.12" height="30" fill="red"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let (outputData, _) = try await optimizer.optimize(data: data)
        let output = String(data: outputData, encoding: .utf8)!

        // Short decimals should not be modified
        XCTAssertTrue(output.contains("x=\"10.5\""))
        XCTAssertTrue(output.contains("width=\"50.12\""))
    }

    // MARK: - Path Whitespace

    func testCollapsePathWhitespace() async throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
        <path d="M 10  20   L 30  40
             L 50  60   Z" fill="red"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let (outputData, _) = try await optimizer.optimize(data: data)
        let output = String(data: outputData, encoding: .utf8)!

        // Check that excessive whitespace is collapsed
        XCTAssertFalse(output.contains("  ")) // No double spaces inside path
        XCTAssertTrue(output.contains("M 10 20 L 30 40 L 50 60 Z"))
    }

    // MARK: - Preservation

    func testPreservesStyleBlock() async throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
        <style>.cls-1 { fill: red; }</style>
        <rect class="cls-1" x="0" y="0" width="100" height="100"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let (outputData, _) = try await optimizer.optimize(data: data)
        let output = String(data: outputData, encoding: .utf8)!

        XCTAssertTrue(output.contains("<style>"))
        XCTAssertTrue(output.contains(".cls-1"))
    }

    func testPreservesViewBox() async throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 150">
        <rect x="0" y="0" width="200" height="150" fill="red"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let (outputData, _) = try await optimizer.optimize(data: data)
        let output = String(data: outputData, encoding: .utf8)!

        XCTAssertTrue(output.contains("viewBox=\"0 0 200 150\""))
    }

    func testPreservesVisualAttributes() async throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
        <rect x="0" y="0" width="100" height="100" fill="red" stroke="blue" opacity="0.5"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let (outputData, _) = try await optimizer.optimize(data: data)
        let output = String(data: outputData, encoding: .utf8)!

        XCTAssertTrue(output.contains("fill=\"red\""))
        XCTAssertTrue(output.contains("stroke=\"blue\""))
        XCTAssertTrue(output.contains("opacity=\"0.5\""))
    }

    func testPreservesDefs() async throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
        <defs>
            <linearGradient id="grad1"><stop offset="0%" style="stop-color:rgb(255,255,0)"/></linearGradient>
        </defs>
        <rect x="0" y="0" width="100" height="100" fill="url(#grad1)"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let (outputData, _) = try await optimizer.optimize(data: data)
        let output = String(data: outputData, encoding: .utf8)!

        XCTAssertTrue(output.contains("<defs>"))
        XCTAssertTrue(output.contains("linearGradient"))
        XCTAssertTrue(output.contains("id=\"grad1\""))
    }

    // MARK: - Edge Cases

    func testAlreadyOptimizedSVGReturnsSmallOrSameSize() async throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect x="0" y="0" width="100" height="100" fill="red"/></svg>
        """
        let data = Data(svg.utf8)
        let (outputData, result) = try await optimizer.optimize(data: data)

        XCTAssertFalse(outputData.isEmpty)
        // Already clean SVG should not grow significantly
        XCTAssertLessThanOrEqual(result.optimizedSize, result.originalSize + 10)
    }

    func testOutputIsValidXML() async throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
        <!-- comment -->
        <metadata><title>Test</title></metadata>
        <g></g>
        <rect x="10.12345" y="20.67890" width="50" height="30" fill="red"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let (outputData, _) = try await optimizer.optimize(data: data)
        let output = String(data: outputData, encoding: .utf8)!

        // Verify the output can be parsed as XML
        let parser = XMLParser(data: outputData)
        let delegate = SimpleXMLDelegate()
        parser.delegate = delegate
        let parsed = parser.parse()
        XCTAssertTrue(parsed, "Output should be valid XML. Content: \(output)")
    }

    func testInvalidDataThrows() async {
        let data = Data([0xFF, 0xFE, 0x00, 0x01])

        do {
            _ = try await optimizer.optimize(data: data)
            XCTFail("Should have thrown for invalid data")
        } catch {
            XCTAssertTrue(error is SVGOptimizationError)
        }
    }
}

// MARK: - Helper

private class SimpleXMLDelegate: NSObject, XMLParserDelegate {
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        // Parsing error will cause parser.parse() to return false
    }
}
