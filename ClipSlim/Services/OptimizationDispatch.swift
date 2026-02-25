import Foundation

enum OptimizationDispatch {
    static let priority: TaskPriority = .utility

    static func run<T: Sendable>(_ operation: @Sendable @escaping () async throws -> T) async throws -> T {
        try await Task.detached(priority: priority, operation: operation).value
    }
}
