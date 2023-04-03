import Foundation
import SolanaSwift
import Combine
import Resolver

final class SendCreateLinkCoordinator: Coordinator<SendCreateLinkCoordinator.Result> {
    // MARK: - Properties
    
    private let result = PassthroughSubject<SendCreateLinkCoordinator.Result, Never>()

    let link: String
    let formatedAmount: String
    
    private let navigationController: UINavigationController
    private let transaction: SendTransaction
    
    // MARK: - Initializer

    init(
        link: String,
        formatedAmount: String,
        navigationController: UINavigationController,
        transaction: SendTransaction
    ) {
        self.link = link
        self.formatedAmount = formatedAmount
        self.navigationController = navigationController
        self.transaction = transaction
        
        super.init()
        bind()
    }
    
    func bind() {
        let transactionHandler = Resolver.resolve(TransactionHandlerType.self)
        let index = transactionHandler.sendTransaction(transaction)
        
        transactionHandler.observeTransaction(transactionIndex: index)
            .compactMap {$0}
            .filter {
                $0.status.error != nil || $0.status.isFinalized || ($0.status.numberOfConfirmations ?? 0) > 0
            }
            .prefix(1)
            .receive(on: RunLoop.main)
            .sink { [weak self] tx in
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
        let viewModel = SendLinkCreatedViewModel(link: link, formatedAmount: formatedAmount)
        let sendLinkCreatedVC = SendLinkCreatedView(viewModel: viewModel).asViewController()
        
        viewModel.close
            .sink(receiveValue: { [unowned self] in
                result.send(.success)
            })
            .store(in: &subscriptions)
        viewModel.share
            .sink(receiveValue: { [weak self] in
                self?.showShareView()
            })
            .store(in: &subscriptions)
        
        navigationController.pushViewController(sendLinkCreatedVC, animated: true)
    }
    
    private func showShareView() {
        let av = UIActivityViewController(activityItems: [link], applicationActivities: nil)
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

// MARK: Result

extension SendCreateLinkCoordinator {
    enum Result {
        case success
        case networkError
        case otherError
    }
}