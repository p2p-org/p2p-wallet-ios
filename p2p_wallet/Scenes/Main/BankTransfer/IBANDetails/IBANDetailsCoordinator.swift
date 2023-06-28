import SwiftUI
import Combine
import BankTransfer

final class IBANDetailsCoordinator: Coordinator<Void> {
    private let navigationController: UINavigationController
    private let eurAccount: UserEURAccount

    init(navigationController: UINavigationController, eurAccount: UserEURAccount) {
        self.navigationController = navigationController
        self.eurAccount = eurAccount
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = IBANDetailsViewModel(eurAccount: eurAccount)
        let view = IBANDetailsView(viewModel: viewModel)

        let vc = view.asViewController(withoutUIKitNavBar: false)
        vc.hidesBottomBarWhenPushed = true
        vc.title = L10n.euroAccount

        navigationController.pushViewController(vc, animated: true)

        return vc.deallocatedPublisher()
            .prefix(1)
            .eraseToAnyPublisher()
    }
}
