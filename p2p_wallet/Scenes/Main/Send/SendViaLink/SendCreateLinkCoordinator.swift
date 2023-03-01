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
                let _ = try await self.execution()
                await MainActor.run { [weak self] in
                    self?.showSendLinkCreatedView()
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
            onClose: { [weak self] in
                self?.result.send(completion: .finished)
            },
            onShare: { [weak self] in
                self?.showShareView()
            }
        )
        sendLinkCreatedVC = UIHostingControllerWithoutNavigation(rootView: view)
        sendCreateLinkVC.show(sendLinkCreatedVC, sender: nil)
    }
    
    private func showShareView() {
        let av = UIActivityViewController(activityItems: [link], applicationActivities: nil)
        sendLinkCreatedVC.present(av, animated: true)
    }
}
