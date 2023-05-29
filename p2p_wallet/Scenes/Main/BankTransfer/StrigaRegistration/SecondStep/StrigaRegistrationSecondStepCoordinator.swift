import SwiftUI
import Combine
import CountriesAPI
import BankTransfer

final class StrigaRegistrationSecondStepCoordinator: Coordinator<Void> {
    private let result = PassthroughSubject<Void, Never>()
    private let navigationController: UINavigationController
    private let data: StrigaUserDetailsResponse

    init(navigationController: UINavigationController, data: StrigaUserDetailsResponse) {
        self.navigationController = navigationController
        self.data = data
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = StrigaRegistrationSecondStepViewModel(data: data)
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
