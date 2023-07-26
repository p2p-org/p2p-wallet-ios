import BankTransfer
import Resolver
import Combine
import SolanaSwift
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
            .sink { [weak self] model in self?.openWithdraw(model: model) }
            .store(in: &subscriptions)

        return vc.deallocatedPublisher().eraseToAnyPublisher()
    }

    private func openBankTransfer() {
        coordinate(to: BankTransferCoordinator(viewController: navigationController))
            .sink(receiveValue: {})
            .store(in: &subscriptions)
    }

    private func openWithdraw(model: StrigaWithdrawalInfo) {
        coordinate(to: WithdrawCoordinator(
            navigationController: navigationController,
            withdrawalInfo: model)
        )
            .handleEvents(receiveOutput: { [unowned self] result in
                switch result {
                case .verified:
                    navigationController.popViewController(animated: true)
                case .canceled, .paymentInitiated:
                    break
                }
            })
            .handleEvents(receiveOutput: { [unowned self] result in
                switch result {
                case .verified:
                    self.navigationController.popToRootViewController(animated: true)
                case .canceled, .paymentInitiated:
                    break
                }
            })
            .flatMap { [unowned self] result in
                switch result {
                case .verified:
                    let transaction = StrigaWithdrawTransaction(
                        challengeId: "1",
                        IBAN: model.IBAN ?? "",
                        BIC: model.BIC ?? "",
                        amount: 120,
                        feeAmount: FeeAmount(
                            transaction: 0,
                            accountBalances: 0
                        )
                    )

                    // delegate work to transaction handler
                    let transactionIndex = Resolver.resolve(TransactionHandlerType.self)
                        .sendTransaction(transaction as! RawTransactionType)

                    // return pending transaction
                    let pendingTransaction = PendingTransaction(
                        trxIndex: transactionIndex,
                        sentAt: Date(),
                        rawTransaction: transaction,
                        status: .sending
                    )
                    return self.openDetails(pendingTransaction: pendingTransaction)
                        .map { _ in Void() }.eraseToAnyPublisher()
                case .canceled, .paymentInitiated:
                    return Just(()).eraseToAnyPublisher()
                }
            }
            .sink { _ in }
            .store(in: &subscriptions)
    }

    private func openDetails(pendingTransaction: PendingTransaction) -> AnyPublisher<TransactionDetailStatus, Never> {
        let viewModel = TransactionDetailViewModel(pendingTransaction: pendingTransaction)

//        self.viewModel.logTransactionProgressOpened()
        return coordinate(to: TransactionDetailCoordinator(
            viewModel: viewModel,
            presentingViewController: navigationController
        ))
    }
}
