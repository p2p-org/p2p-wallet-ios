import BankTransfer
import Combine
import CountriesAPI
import Foundation
import Resolver
import SafariServices

enum BankTransferInfoCoordinatorResult {
    case canceled
    case completed
}

final class BankTransferInfoCoordinator: Coordinator<BankTransferInfoCoordinatorResult> {
    private let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<BankTransferInfoCoordinatorResult, Never> {
        let viewModel = BankTransferInfoViewModel()
        let controller = BankTransferInfoView(viewModel: viewModel).asViewController(
            withoutUIKitNavBar: false,
            ignoresKeyboard: true
        )
        controller.hidesBottomBarWhenPushed = true

        viewModel.openBrowser.flatMap { [weak controller] url in
            let safari = SFSafariViewController(url: url)
            controller?.show(safari, sender: nil)
            return safari.deallocatedPublisher()
        }.sink {}.store(in: &subscriptions)

        navigationController.pushViewController(controller, animated: true)

        return Publishers.Merge(
            // Ignore deallocation event if open registration triggered
            Publishers.Merge(
                controller.deallocatedPublisher().map { true },
                viewModel.openRegistration.map { _ in false }
            )
            .prefix(1)
            .filter { $0 }
            .map { _ in BankTransferInfoCoordinatorResult.canceled }
            .eraseToAnyPublisher(),
            viewModel.openRegistration
                .flatMap { [unowned self] in
                    self.coordinate(
                        to: StrigaRegistrationFirstStepCoordinator(
                            navigationController: self.navigationController
                        )
                    )
                }
                .handleEvents(receiveOutput: { [weak self] result in
                    guard let self else { return }
                    switch result {
                    case .completed:
                        self.navigationController.setViewControllers(
                            [self.navigationController.viewControllers.first!],
                            animated: false
                        )
                    case .canceled:
                        break
                    }
                })
                .map { result in
                    switch result {
                    case .completed:
                        return BankTransferInfoCoordinatorResult.completed
                    case .canceled:
                        return BankTransferInfoCoordinatorResult.canceled
                    }
                }
        )
        .prefix(1)
        .eraseToAnyPublisher()
    }
}
