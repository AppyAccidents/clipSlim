import XCTest
@testable import ClipSlim

final class OptimizationDispatchTests: XCTestCase {

    private enum TestError: Error, Equatable {
        case sample
    }

    func testRunUsesUtilityPriority() async throws {
        XCTAssertEqual(OptimizationDispatch.priority, .utility)

        let expectedRawPriority = await Task.detached(priority: OptimizationDispatch.priority) {
            Task.currentPriority.rawValue
        }.value
        let observedRawPriority = try await OptimizationDispatch.run {
            Task.currentPriority.rawValue
        }

        XCTAssertEqual(observedRawPriority, expectedRawPriority)
    }

    func testRunReturnsValue() async throws {
        let value = try await OptimizationDispatch.run {
            "optimized"
        }

        XCTAssertEqual(value, "optimized")
    }

    func testRunPropagatesThrownError() async {
        do {
            _ = try await OptimizationDispatch.run { () async throws -> Int in
                throw TestError.sample
            }
            XCTFail("Expected OptimizationDispatch.run to throw")
        } catch let error as TestError {
            XCTAssertEqual(error, .sample)
        } catch {
            XCTFail("Expected TestError.sample, got \(error)")
        }
    }
}
