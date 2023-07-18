import Foundation
import FeeRelayerSwift
import Combine

class MockRelayContextManagerBase: RelayContextManager {
    var currentContext: FeeRelayerSwift.RelayContext? {
        fatalError()
    }
    
    var contextPublisher: AnyPublisher<RelayContext?, Never> {
        fatalError()
    }
    
    @discardableResult
    func update() async throws -> RelayContext {
        fatalError()
    }
    
    func replaceContext(by context: RelayContext) {
        fatalError()
    }
}
