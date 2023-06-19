import Foundation
import SolanaSwift
import Combine
import Resolver
import AnalyticsManager

final class SendCreateLinkCoordinator: Coordinator<SendCreateLinkCoordinator.Result> {
    // MARK: - Dependencies
    @Injected private var analyticsManager: AnalyticsManager

    // MARK: - Properties
    
    private let result = PassthroughSubject<SendCreateLinkCoordinator.Result, Never>()

    let link: String
    let formatedAmount: String
    
    private let navigationController: UINavigationController
    private let transaction: SendTransaction
    private let intermediatePubKey: String
    
    // MARK: - Initializer

    init(
        link: String,
        formatedAmount: String,
        navigationController: UINavigationController,
        transaction: SendTransaction,
        intermediatePubKey: String
    ) {
        self.link = link
        self.formatedAmount = formatedAmount
        self.navigationController = navigationController
        self.transaction = transaction
        self.intermediatePubKey = intermediatePubKey
        
        super.init()
        bind()
    }
    
    func bind() {
        let transactionHandler = Resolver.resolve(TransactionHandlerType.self)
        let index = transactionHandler.sendTransaction(transaction)
        
        transactionHandler.observeTransaction(transactionIndex: index)
            .compactMap {$0}
            .filter { $0.isConfirmedOrError }
            .prefix(1)
            .receive(on: RunLoop.main)
            .sink { [weak self] tx in
                self?.logSend(signature: tx.transactionId)

                if let error = tx.status.error {
                    if (error as NSError).isNetworkConnectionError {
                        self?.result.send(.networkError)
                    } else {
                        self?.showOtherErrorView()
                    }
                } else {
                    self?.showSendLinkCreatedView()
                }
            }
            .store(in: &subscriptions)
    }
    
    // MARK: - Builder

    override func start() -> AnyPublisher<SendCreateLinkCoordinator.Result, Never> {
        let view = SendCreateLinkView()
        let sendCreateLinkVC = UIHostingControllerWithoutNavigation(rootView: view)
        navigationController.pushViewController(sendCreateLinkVC, animated: true)
        
        return result.prefix(1).eraseToAnyPublisher()
    }
    
    // MARK: - Helper

    private func showSendLinkCreatedView() {
        let viewModel = SendLinkCreatedViewModel(
            link: link,
            formatedAmount: formatedAmount,
            intermediateAccountPubKey: intermediatePubKey
        )
        let sendLinkCreatedVC = SendLinkCreatedView(viewModel: viewModel).asViewController()
        
        viewModel.close
            .sink(receiveValue: { [unowned self] in
                result.send(.success)
            })
            .store(in: &subscriptions)
        viewModel.share
            .sink(receiveValue: { [weak self] in
                guard let self else { return }
                self.showShareView(
                    link: self.link,
                    amount: self.transaction.amount,
                    symbol: self.transaction.walletToken.token.symbol
                )
            })
            .store(in: &subscriptions)
        
        navigationController.pushViewController(sendLinkCreatedVC, animated: true)
    }
    
    private func showShareView(link: String, amount: Double, symbol: String) {
        // get sender
        let userWalletManager = Resolver.resolve(UserWalletManager.self)
        let sender = userWalletManager.wallet?.name ?? userWalletManager.wallet?.account.publicKey.base58EncodedString
        
        // assertion
        guard let sender,
              let url = URL(string: link)
        else { return }
        
        // form item to share
        let shareItems: [Any] = [
            SentViaLinkActivityItemSource(
                sender: sender,
                amount: amount,
                symbol: symbol,
                url: url
            )
        ]
        
        // create share sheet
        let av = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
        
        // present share sheet
        navigationController.present(av, animated: true)
    }
    
    private func showOtherErrorView() {
        let view = SendCreateLinkErrorView { [unowned self] in
            result.send(.otherError)
        }
        let vc = UIHostingControllerWithoutNavigation(rootView: view)
        navigationController.pushViewController(vc, animated: true)
    }
}

private extension SendCreateLinkCoordinator {
    func logSend(signature: String?) {
        guard case let .sendNewConfirmButtonClick(sendFlow, token, max, amountToken, amountUSD, fee, fiatInput, _, _) = transaction.analyticEvent, let signature else { return }
        analyticsManager.log(event: .sendNewConfirmButtonClick(sendFlow: sendFlow, token: token, max: max, amountToken: amountToken, amountUSD: amountUSD, fee: fee, fiatInput: fiatInput, signature: signature, pubKey: intermediatePubKey))
    }
}

// MARK: Result

extension SendCreateLinkCoordinator {
    enum Result {
        case success
        case networkError
        case otherError
    }
}
