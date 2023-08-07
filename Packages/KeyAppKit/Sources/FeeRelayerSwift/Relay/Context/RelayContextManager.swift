import Combine
import Foundation

/// Manager class for RelayContext
public protocol RelayContextManager {
    /// Current RelayContext
    var currentContext: RelayContext? { get }

    /// Publisher for current RelayContext
    var contextPublisher: AnyPublisher<RelayContext?, Never> { get }

    /// Update current context
    @discardableResult
    func update() async throws -> RelayContext

    /// Modify context locally
    func replaceContext(by context: RelayContext)
}

public extension RelayContextManager {
    func getCurrentContextOrUpdate() async throws -> RelayContext {
        if let context = currentContext {
            return context
        }
        return try await update()
    }
}

public enum RelayContextManagerError: Swift.Error, Equatable {
    case invalidContext
}
