//
//  SellPendingHostingController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/01/2023.
//

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
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setNavigationBar() {
        let customBackButton = UIBarButtonItem(image: .backArrow, style: .plain, target: self, action: #selector(backAction(sender:)))
        navigationItem.leftBarButtonItem = customBackButton
        navigationItem.hidesBackButton = true
        navigationItem.largeTitleDisplayMode = .never
    }

    @objc func backAction(sender: UIBarButtonItem) {
        guard shouldShowAlert else {
            self.backButtonHandler?()
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
                }
            ]
        )
    }
}
