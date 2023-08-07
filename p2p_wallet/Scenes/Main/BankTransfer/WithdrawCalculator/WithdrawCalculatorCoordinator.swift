import BankTransfer
import Combine
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import SolanaSwift
import UIKit

final class WithdrawCalculatorCoordinator: Coordinator<WithdrawCalculatorCoordinator.Result> {
    private let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<WithdrawCalculatorCoordinator.Result, Never> {
        let viewModel = WithdrawCalculatorViewModel()
        let view = WithdrawCalculatorView(viewModel: viewModel)
        let vc = view.asViewController(withoutUIKitNavBar: false)
        vc.title = L10n.withdraw
        vc.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(vc, animated: true)

        viewModel.openBankTransfer
            .sink { [weak self] _ in self?.openBankTransfer() }
            .store(in: &subscriptions)

        return Publishers.Merge(
            viewModel.openWithdraw
                .flatMap { [unowned self] model, amount in
                    openWithdraw(model: model, amount: amount)
                }
                .handleEvents(receiveOutput: { [unowned self] tx in
                    if let tx {
                        navigationController.popViewController(animated: true)
                    }
                })
                .compactMap { $0 }
                .map { WithdrawCalculatorCoordinator.Result.transaction($0) }
                .eraseToAnyPublisher(),
            vc.deallocatedPublisher()
                .map { WithdrawCalculatorCoordinator.Result.canceled }
                .eraseToAnyPublisher()
        ).prefix(1).eraseToAnyPublisher()
    }

    private func openBankTransfer() {
        coordinate(to: BankTransferCoordinator(viewController: navigationController))
            .sink(receiveValue: {})
            .store(in: &subscriptions)
    }

    private func openWithdraw(model: StrigaWithdrawalInfo, amount: Double) -> AnyPublisher<PendingTransaction?, Never> {
        coordinate(to: WithdrawCoordinator(
            navigationController: navigationController,
            withdrawalInfo: model
        ))
        .asyncMap { result -> (WithdrawCoordinator.Result, TokenPrice?) in
            let priceService = Resolver.resolve(PriceService.self)
            let prices = try? await priceService.getPrice(
                token: SolanaToken.usdc,
                fiat: Defaults.fiat.rawValue
            )
            return (result, prices)
        }
        .receive(on: DispatchQueue.main)
        .handleEvents(receiveOutput: { [unowned self] result, _ in
            switch result {
            case .verified:
                navigationController.popToRootViewController(animated: true)
            case .canceled, .paymentInitiated:
                break
            }
        })
        .map { result, prices -> PendingTransaction? in
            switch result {
            case let .paymentInitiated(challangeId):
                let transaction = StrigaWithdrawTransaction(
                    challengeId: challangeId,
                    IBAN: model.IBAN ?? "",
                    BIC: model.BIC ?? "",
                    amount: amount,
                    token: .usdc,
                    tokenPrice: prices,
                    feeAmount: FeeAmount(
                        transaction: 0,
                        accountBalances: 0
                    )
                )

                // delegate work to transaction handler
                let transactionIndex = Resolver.resolve(TransactionHandlerType.self)
                    .sendTransaction(transaction, status: .sending)

                // return pending transaction
                let pendingTransaction = PendingTransaction(
                    trxIndex: transactionIndex,
                    sentAt: Date(),
                    rawTransaction: transaction,
                    status: .sending
                )
                return pendingTransaction
            case let .verified(IBAN, BIC):
                // Fake transaction for now
                let sendTransaction = SendTransaction(
                    isFakeSendTransaction: false,
                    isFakeSendTransactionError: false,
                    isFakeSendTransactionNetworkError: false,
                    isLinkCreationAvailable: false, // TODO: Check
                    recipient: .init(
                        address: "",
                        category: .solanaAddress,
                        attributes: .funds
                    ),
                    sendViaLinkSeed: nil,
                    amount: amount,
                    amountInFiat: 0.01,
                    walletToken: .nativeSolana(pubkey: "adfasdf", lamport: 200_000_000),
                    address: "adfasdf",
                    payingFeeWallet: .nativeSolana(pubkey: "adfasdf", lamport: 200_000_000),
                    feeAmount: .init(transaction: 10000, accountBalances: 2_039_280),
                    currency: "USD",
                    analyticEvent: .sendNewConfirmButtonClick(
                        sendFlow: "",
                        token: "",
                        max: false,
                        amountToken: 0,
                        amountUSD: 0,
                        fee: false,
                        fiatInput: false,
                        signature: "",
                        pubKey: nil
                    )
                )

                let transaction = StrigaWithdrawSendTransaction(
                    sendTransaction: sendTransaction,
                    IBAN: IBAN,
                    BIC: BIC,
                    amount: amount,
                    feeAmount: .zero
                )

                // delegate work to transaction handler
                let transactionIndex = Resolver.resolve(TransactionHandlerType.self)
                    .sendTransaction(
                        transaction,
                        status: .confirmationNeeded
                    )

                // return pending transaction
                let pendingTransaction = PendingTransaction(
                    trxIndex: transactionIndex,
                    sentAt: Date(),
                    rawTransaction: transaction,
                    status: .confirmationNeeded
                )
                return pendingTransaction
            case .canceled:
                return nil
            }
        }
        .eraseToAnyPublisher()
    }
}

extension WithdrawCalculatorCoordinator {
    enum Result {
        case transaction(PendingTransaction)
        case canceled
    }
}
