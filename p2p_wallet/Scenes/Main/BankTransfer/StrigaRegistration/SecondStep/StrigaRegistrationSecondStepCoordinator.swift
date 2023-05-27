import SwiftUI
import Combine
import CountriesAPI

final class StrigaRegistrationSecondStepCoordinator: Coordinator<Void> {
    private let result = PassthroughSubject<Void, Never>()
    private let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = StrigaRegistrationSecondStepViewModel()
        let view = StrigaRegistrationSecondStepView(viewModel: viewModel)
        let vc = view.asViewController(withoutUIKitNavBar: false)
        vc.title = L10n.stepOf(2, 3)
        navigationController.pushViewController(vc, animated: true)

        return Publishers.Merge(
            vc.deallocatedPublisher(),
            result.eraseToAnyPublisher()
        )
        .prefix(1).eraseToAnyPublisher()
    }
}
