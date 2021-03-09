//
//  TokenSettingsCloseAccountConfirmationVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 01/03/2021.
//

import Foundation

class TokenSettingsCloseAccountConfirmationVC: WLModalVC {
    let symbol: String
    var completion: (() -> Void)?
    init(symbol: String) {
        self.symbol = symbol
        super.init()
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    override func setUp() {
        super.setUp()
        stackView.addArrangedSubviews([
            UILabel(text: L10n.closeAccount(symbol) + "?", textSize: 17, weight: .semibold)
                .padding(.init(x: 20, y: 0)),
            BEStackViewSpacing(5),
            UILabel(
                text: L10n.YourBalanceWillBeConvertedAndTransferredToYourMainSOLWalletAndYourAddressWillBeDisabled.thisActionCanNotBeUndone(symbol),
                weight: .medium,
                textColor: .textSecondary,
                numberOfLines: 0
            )
                .padding(.init(x: 20, y: 0)),
            BEStackViewSpacing(20),
            UIView.separator(height: 1, color: .separator),
            BEStackViewSpacing(20),
            UILabel(text: L10n.closeTokenAccount, textSize: 17, weight: .medium, textColor: .alert, textAlignment: .center)
                .padding(.init(all: 18), backgroundColor: .f6f6f8, cornerRadius: 12)
                .onTap(self, action: #selector(buttonCloseDidTouch))
                .padding(.init(x: 20, y: 0)),
            BEStackViewSpacing(10),
            UILabel(text: L10n.cancel, textSize: 17, weight: .medium, textColor: .h5887ff, textAlignment: .center)
                .padding(.init(all: 18), backgroundColor: .f6f6f8, cornerRadius: 12)
                .onTap(self, action: #selector(back))
                .padding(.init(x: 20, y: 0))
        ])
    }
    
    @objc func buttonCloseDidTouch() {
        completion?()
    }
}

extension TokenSettingsCloseAccountConfirmationVC: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return FlexibleHeightPresentationController(position: .bottom, presentedViewController: presented, presenting: presenting)
    }
}
