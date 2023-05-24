import SwiftUI
import Combine

final class StrigaRegistrationDataCoordinator: Coordinator<String?> {
    private let result = PassthroughSubject<String?, Never>()

    override func start() -> AnyPublisher<String?, Never> {
        let viewModel = StrigaRegistrationDataViewModel()
        let view = StrigaRegistrationDataView(viewModel: viewModel)
        let vc = view.asViewController(withoutUIKitNavBar: false)

        return result.first().eraseToAnyPublisher()
    }
}
