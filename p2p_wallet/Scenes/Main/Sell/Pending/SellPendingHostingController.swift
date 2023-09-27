import Foundation
import SwiftUI

class SellPendingHostingController<Content: View>: UIHostingController<Content> {
    var backButtonHandler: (() -> Void)?
    var shouldShowAlert: Bool

    init(rootView: Content, shouldShowAlert: Bool) {
        self.shouldShowAlert = shouldShowAlert
        super.init(rootView: rootView)
        setNavigationBar()
    }

    @available(*, unavailable)
    @MainActor dynamic required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setNavigationBar() {
        let customBackButton = UIBarButtonItem(
            image: .init(resource: .backArrow),
            style: .plain,
            target: self,
            action: #selector(backAction(sender:))
        )
        navigationItem.leftBarButtonItem = customBackButton
        navigationItem.hidesBackButton = true
        navigationItem.largeTitleDisplayMode = .never
    }

    @objc func backAction(sender _: UIBarButtonItem) {
        guard shouldShowAlert else {
            backButtonHandler?()
            return
        }
        // custom actions here
        showAlert(
            title: L10n.areYouSure,
            message: L10n.areYouSureYouWantToInterruptCashOutProcessYourTransactionWonTBeFinished,
            actions: [
                UIAlertAction(title: L10n.continueTransaction, style: .default),
                UIAlertAction(title: L10n.interrupt, style: .destructive) { [unowned self] _ in
                    self.backButtonHandler?()
                },
            ]
        )
    }
}
