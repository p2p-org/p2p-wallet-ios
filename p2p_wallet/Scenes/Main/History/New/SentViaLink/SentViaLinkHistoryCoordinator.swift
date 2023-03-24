import Foundation
import KeyAppUI
import Combine

final class SentViaLinkHistoryCoordinator: SmartCoordinator<Void> {
    // MARK: - Properties

    private let transactionsPublisher: AnyPublisher<[SendViaLinkTransactionInfo], Never>
    private var transactionDetailVC: CustomPresentableViewController!
    
    // MARK: - Initializer

    init(
        transactionsPublisher: AnyPublisher<[SendViaLinkTransactionInfo], Never>,
        presentation: SmartCoordinatorPresentation
    ) {
        self.transactionsPublisher = transactionsPublisher
        super.init(presentation: presentation)
    }
    
    // MARK: - Methods

    override func build() -> UIViewController {
        // create viewController
        let vc = SentViaLinkHistoryView(
            transactionsPublisher: transactionsPublisher
        ) { [weak self] selectedTransaction in
            // transaction selected
            self?.openSendViaLinkTransactionDetail(transaction: selectedTransaction)
        }
            .asViewController(withoutUIKitNavBar: false)
        vc.title = L10n.sentViaOneTimeLink
        vc.view.backgroundColor = Asset.Colors.smoke.color
        
        return vc
    }
    
    // MARK: - Helpers

    private func openSendViaLinkTransactionDetail(transaction: SendViaLinkTransactionInfo) {
        // get publisher
        let transactionPublisher = transactionsPublisher
            .compactMap { $0.first(where: {$0.seed == transaction.seed} ) }
            .eraseToAnyPublisher()
        
        // create view
        let view = SentViaLinkTransactionDetailView(
            transactionPublisher: transactionPublisher,
            onShare: { [weak self] in
                self?.showShareView(link: .sendViaLinkPrefix + "/" + transaction.seed)
            },
            onClose: { [weak self] in
                self?.transactionDetailVC.dismiss(animated: true)
            }
        )
        
        // create bottom sheet
        transactionDetailVC = UIBottomSheetHostingController(rootView: view, ignoresKeyboard: true)
        transactionDetailVC.view.layer.cornerRadius = 20
        
        // present bottom sheet
        presentation.presentingViewController.present(transactionDetailVC, interactiveDismissalType: .standard)
        
        // update presentation layout when info changes
        transactionPublisher
            .receive(on: RunLoop.main)
            .sink { _ in
                DispatchQueue.main.async { [weak self] in
                    self?.transactionDetailVC.updatePresentationLayout(animated: true)
                }
            }
            .store(in: &subscriptions)
    }
    
    private func showShareView(link: String) {
        let av = UIActivityViewController(activityItems: [link], applicationActivities: nil)
        transactionDetailVC.present(av, animated: true)
    }
}
