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
        ) { selectedTransaction in
            
        }
            .asViewController(withoutUIKitNavBar: false)
        vc.title = L10n.sentViaOneTimeLink
        vc.view.backgroundColor = Asset.Colors.smoke.color
        
        return vc
    }
    
    // MARK: - Helpers

    
}
