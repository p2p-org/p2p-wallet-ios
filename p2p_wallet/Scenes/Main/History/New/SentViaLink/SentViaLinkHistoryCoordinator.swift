import Foundation
import KeyAppUI
import Combine
import Resolver
import Send

final class SentViaLinkHistoryCoordinator: SmartCoordinator<Void> {
    // MARK: - Properties

    private var transactionDetailVC: CustomPresentableViewController!
    
    private var transactionsPublisher: AnyPublisher<[SendViaLinkTransactionInfo], Never> {
        let sendViaLinkStorage: SendViaLinkStorage = Resolver.resolve()
        return sendViaLinkStorage.transactionsPublisher
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
        guard let url = try? Resolver.resolve(SendViaLinkDataService.self)
            .restoreURL(givenSeed: transaction.seed)
        else {
            return
        }
        
        // get publisher
        let transactionPublisher = transactionsPublisher
            .compactMap { $0.first(where: {$0.seed == transaction.seed} ) }
            .eraseToAnyPublisher()
        
        // create view
        let view = SentViaLinkTransactionDetailView(
            transactionPublisher: transactionPublisher,
            onShare: { [weak self] in
                self?.showShareView(
                    link: url.absoluteString,
                    amount: transaction.amount,
                    symbol: transaction.token.symbol
                )
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
        transactionDetailVC.present(av, animated: true)
    }
}
