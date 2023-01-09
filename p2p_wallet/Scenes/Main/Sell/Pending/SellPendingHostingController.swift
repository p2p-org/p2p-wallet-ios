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
    
    override init(rootView: Content) {
        super.init(rootView: rootView)
        setNavigationBar()
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setNavigationBar() {
        let customBackButton = UIBarButtonItem(image: .backArrow, style: .plain, target: self, action: #selector(backAction(sender:)))
        customBackButton.imageInsets = UIEdgeInsets(top: 2, left: -8, bottom: 0, right: 0)
        navigationItem.leftBarButtonItem = customBackButton
        navigationItem.hidesBackButton = true
        navigationItem.largeTitleDisplayMode = .never
    }

    @objc func backAction(sender: UIBarButtonItem) {
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
