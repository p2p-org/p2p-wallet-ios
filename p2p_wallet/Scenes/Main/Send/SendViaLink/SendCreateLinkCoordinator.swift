import Foundation
import SolanaSwift

final class SendCreateLinkCoordinator: SmartCoordinator<Void> {
    // MARK: - Properties

    let link: String
    let formatedAmount: String
    
    var execution: () async throws -> TransactionID
    var sendCreateLinkVC: UIViewController!
    var sendLinkCreatedVC: UIViewController!
    
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
        super.init(presentation: SmartCoordinatorPushPresentation(navigationController))
    }
    
    // MARK: - Builder

    override func build() -> UIViewController {
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

        return sendCreateLinkVC
    }
    
    // MARK: - Helper

    private func showSendLinkCreatedView() {
        let view = SendLinkCreatedView(
            link: link,
            formatedAmount: formatedAmount,
            onClose: { [unowned self] in
                result.send(completion: .finished)
            },
            onShare: { [unowned self] in
                showShareView()
            }
        )
        sendLinkCreatedVC = UIHostingControllerWithoutNavigation(rootView: view)
        sendCreateLinkVC.show(sendLinkCreatedVC, sender: nil)
    }
    
    private func showShareView() {
        let av = UIActivityViewController(activityItems: [link], applicationActivities: nil)
        sendLinkCreatedVC.present(av, animated: true)
    }
    
    private func showErrorView() {
        let view = SendCreateLinkErrorView { [unowned self] in
            result.send(completion: .finished)
        }
        let vc = UIHostingControllerWithoutNavigation(rootView: view)
        sendCreateLinkVC.show(vc, sender: nil)
    }
}
