import Foundation
import SolanaSwift
import Combine

final class SendCreateLinkCoordinator: Coordinator<SendCreateLinkCoordinator.Result> {
    // MARK: - Properties
    
    private let result = PassthroughSubject<SendCreateLinkCoordinator.Result, Never>()

    let link: String
    let formatedAmount: String
    
    var execution: () async throws -> TransactionID
    private let navigationController: UINavigationController
    
    private var sendCreateLinkVC: UIViewController!
    
    // MARK: - Initializer

    init(
        link: String,
        formatedAmount: String,
        navigationController: UINavigationController,
        execution: @escaping () async throws -> TransactionID
    ) {
        self.link = link
        self.formatedAmount = formatedAmount
        self.execution = execution
        self.navigationController = navigationController
    }
    
    // MARK: - Builder

    override func start() -> AnyPublisher<SendCreateLinkCoordinator.Result, Never> {
        let view = SendCreateLinkView {
            Task { [unowned self] in
                do {
                    let _ = try await self.execution()
                    await MainActor.run { [weak self] in
                        self?.showSendLinkCreatedView()
                    }
                } catch {
                    await MainActor.run { [weak self] in
                        self?.showErrorView()
                    }
                }
            }
        }
        sendCreateLinkVC = UIHostingControllerWithoutNavigation(rootView: view)
        navigationController.pushViewController(sendCreateLinkVC, animated: true)
        
        sendCreateLinkVC.deallocatedPublisher()
            .sink(receiveValue: { [weak self] _ in
                self?.result.send(.normal)
            })
            .store(in: &subscriptions)
        
        return result.prefix(1).eraseToAnyPublisher()
    }
    
    // MARK: - Helper

    private func showSendLinkCreatedView() {
        let view = SendLinkCreatedView(
            link: link,
            formatedAmount: formatedAmount,
            onClose: { [unowned self] in
                result.send(.normal)
            },
            onShare: { [unowned self] in
                showShareView()
            }
        )
        let sendLinkCreatedVC = UIHostingControllerWithoutNavigation(rootView: view)
//        navigationController.pushViewController(sendLinkCreatedVC, animated: true) // Not works in ios 16.4 (Dev beta). Don't know why??
        sendCreateLinkVC.show(sendLinkCreatedVC, sender: nil)
    }
    
    private func showShareView() {
        let av = UIActivityViewController(activityItems: [link], applicationActivities: nil)
        sendCreateLinkVC.present(av, animated: true)
    }
    
    private func showErrorView() {
        let view = SendCreateLinkErrorView { [unowned self] in
            result.send(.error)
        }
        let vc = UIHostingControllerWithoutNavigation(rootView: view)
//        navigationController.pushViewController(vc, animated: true) // Not works in ios 16.4 (Dev beta). Don't know why??
        sendCreateLinkVC.show(vc, sender: nil)
    }
}

// MARK: Result

extension SendCreateLinkCoordinator {
    enum Result {
        case error
        case normal
    }
}
