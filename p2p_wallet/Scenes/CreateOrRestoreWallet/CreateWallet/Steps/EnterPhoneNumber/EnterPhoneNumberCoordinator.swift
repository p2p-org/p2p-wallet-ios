import Foundation

enum EnterPhoneNumberCoordinatorResult {
    case cancel
    case success
}

final class EnterPhoneNumberCoordinator: Coordinator<EnterPhoneNumberCoordinatorResult> {
    
    open func start() -> AnyPublisher<ResultType, Never> {
        
    }

}
