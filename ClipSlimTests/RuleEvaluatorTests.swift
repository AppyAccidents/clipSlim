import XCTest
@testable import ClipSlim

final class RuleEvaluatorTests: XCTestCase {

    let evaluator = RuleEvaluator.shared

    func testFileSizeRuleMatches() {
        let rule = FolderRule(condition: .fileSizeGreaterThan(bytes: 1000), action: .compressAggressive)
        let context = RuleEvaluator.FileContext(fileSize: 2000, format: .jpeg, fileName: "test.jpg", hasAlpha: false, width: 100, height: 100)
        let result = evaluator.evaluate(rules: [rule], context: context)
        XCTAssertNotNil(result)
        if case .compressAggressive = result! {
            // pass
        } else {
            XCTFail("Expected compressAggressive")
        }
    }

    func testFileSizeRuleDoesNotMatch() {
        let rule = FolderRule(condition: .fileSizeGreaterThan(bytes: 5000), action: .compressAggressive)
        let context = RuleEvaluator.FileContext(fileSize: 2000, format: .jpeg, fileName: "test.jpg", hasAlpha: false, width: 100, height: 100)
        let result = evaluator.evaluate(rules: [rule], context: context)
        XCTAssertNil(result)
    }

    func testFormatRuleMatches() {
        let rule = FolderRule(condition: .formatIs("PNG"), action: .convertTo("JPEG"))
        let context = RuleEvaluator.FileContext(fileSize: 1000, format: .png, fileName: "test.png", hasAlpha: false, width: 100, height: 100)
        let result = evaluator.evaluate(rules: [rule], context: context)
        XCTAssertNotNil(result)
    }

    func testFilenameContainsRule() {
        let rule = FolderRule(condition: .filenameContains("screenshot"), action: .keepHighQuality)
        let context = RuleEvaluator.FileContext(fileSize: 1000, format: .png, fileName: "Screenshot 2024.png", hasAlpha: false, width: 100, height: 100)
        let result = evaluator.evaluate(rules: [rule], context: context)
        XCTAssertNotNil(result)
    }

    func testDisabledRuleIsSkipped() {
        let rule = FolderRule(condition: .fileSizeGreaterThan(bytes: 100), action: .skip, isEnabled: false)
        let context = RuleEvaluator.FileContext(fileSize: 2000, format: .jpeg, fileName: "test.jpg", hasAlpha: false, width: 100, height: 100)
        let result = evaluator.evaluate(rules: [rule], context: context)
        XCTAssertNil(result)
    }

    func testFirstMatchingRuleWins() {
        let rule1 = FolderRule(condition: .fileSizeGreaterThan(bytes: 100), action: .compressAggressive)
        let rule2 = FolderRule(condition: .fileSizeGreaterThan(bytes: 100), action: .skip)
        let context = RuleEvaluator.FileContext(fileSize: 2000, format: .jpeg, fileName: "test.jpg", hasAlpha: false, width: 100, height: 100)
        let result = evaluator.evaluate(rules: [rule1, rule2], context: context)
        if case .compressAggressive = result! {
            // First rule wins
        } else {
            XCTFail("Expected first rule to win")
        }
    }
}
