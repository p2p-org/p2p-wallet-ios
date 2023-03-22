import Foundation
import KeyAppUI
import Combine

final class SentViaLinkHistoryCoordinator: SmartCoordinator<Void> {
    // MARK: - Properties

    private let transactionsPublisher: AnyPublisher<[SendViaLinkTransactionInfo], Never>
    
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
            onShare: {
                
            },
            onClose: {
                
            }
        )
        
        // create bottom sheet
        let vc = UIBottomSheetHostingController(rootView: view, ignoresKeyboard: true)
        vc.view.layer.cornerRadius = 20
        
        // present bottom sheet
        presentation.presentingViewController.present(vc, interactiveDismissalType: .standard)
        
        // update presentation layout when info changes
        transactionPublisher
            .receive(on: RunLoop.main)
            .sink { _ in
                DispatchQueue.main.async { [weak vc] in
                    vc?.updatePresentationLayout(animated: true)
                }
            }
            .store(in: &subscriptions)
    }
}
