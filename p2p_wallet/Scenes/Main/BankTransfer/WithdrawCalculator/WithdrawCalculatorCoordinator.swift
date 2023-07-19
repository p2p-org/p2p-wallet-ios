import Combine
import UIKit

final class WithdrawCalculatorCoordinator: Coordinator<Void> {
    private let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = WithdrawCalculatorViewModel()
        let view = WithdrawCalculatorView(viewModel: viewModel)
        let vc = view.asViewController(withoutUIKitNavBar: false)
        vc.title = L10n.withdraw
        vc.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(vc, animated: true)

        viewModel.openBankTransfer
            .sink { [weak self] _ in self?.openBankTransfer() }
            .store(in: &subscriptions)

        viewModel.openWithdraw
            .sink { [weak self] _ in self?.openWithdraw() }
            .store(in: &subscriptions)

        return vc.deallocatedPublisher().eraseToAnyPublisher()
    }

    private func openBankTransfer() {
        coordinate(to: BankTransferCoordinator(viewController: navigationController))
            .sink(receiveValue: {})
            .store(in: &subscriptions)
    }

    private func openWithdraw() {
        // todo
    }
}
