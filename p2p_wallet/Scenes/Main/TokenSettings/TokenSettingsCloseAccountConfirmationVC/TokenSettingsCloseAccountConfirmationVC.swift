//
//  TokenSettingsCloseAccountConfirmationVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 01/03/2021.
//

import Foundation

class TokenSettingsCloseAccountConfirmationVC: WLIndicatorModalVC {
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
        let stackView = UIStackView(axis: .vertical, spacing: 20, alignment: .fill, distribution: .fill)
        containerView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 0, y: 20))
        
        stackView.addArrangedSubviews([
            UILabel(text: L10n.closeAccount(symbol) + "?", textSize: 17, weight: .semibold)
                .padding(.init(x: 20, y: 0)),
            BEStackViewSpacing(5),
            UILabel(
                text: L10n.areYouSureYouWantToDeleteThisTokenAccountThisWillPermanentlyDisableTokenTransfersToThisAddressAndRemoveItFromYourWallet,
                weight: .medium,
                textColor: .textSecondary,
                numberOfLines: 0
            )
                .padding(.init(x: 20, y: 0)),
            BEStackViewSpacing(20),
            UIView.defaultSeparator(),
            BEStackViewSpacing(20),
            UILabel(text: L10n.closeTokenAccount, textSize: 17, weight: .medium, textColor: .alert, textAlignment: .center)
                .padding(.init(all: 18), backgroundColor: .grayPanel, cornerRadius: 12)
                .onTap(self, action: #selector(buttonCloseDidTouch))
                .padding(.init(x: 20, y: 0)),
            BEStackViewSpacing(10),
            UILabel(text: L10n.cancel, textSize: 17, weight: .medium, textColor: .h5887ff.onDarkMode(.white), textAlignment: .center)
                .padding(.init(all: 18), backgroundColor: .grayPanel, cornerRadius: 12)
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
