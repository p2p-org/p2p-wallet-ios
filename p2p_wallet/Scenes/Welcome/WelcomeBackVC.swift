//
//  WelcomeBackVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation
import SwiftUI

class WelcomeBackVC: WLIntroVC {
    lazy var goToWalletButton = WLButton.stepButton(type: .blue, label: L10n.goToWallet)
        .onTap(self, action: #selector(buttonGoToWalletDidTouch))
    
    let phrases: [String]
    init(phrases: [String]) {
        self.phrases = phrases
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setUp() {
        super.setUp()
        
        // add center image
        var i = 3
        let logoImageView = UIImageView(width: 200, height: 200, image: .welcomeBack)
        let spacer2 = UIView.spacer
        stackView.insertArrangedSubviewsWithCustomSpacing([
            logoImageView.centeredHorizontallyView,
            spacer2
        ], at: &i)
        
        spacer2.heightAnchor.constraint(equalTo: spacer1.heightAnchor)
            .isActive = true
        
        titleLabel.text = L10n.welcomeBack
        
        buttonsStackView.addArrangedSubviews([
            goToWalletButton,
            UIView(height: 56)
        ])
    }
    
    @objc func buttonGoToWalletDidTouch() {
        UIApplication.shared.showIndetermineHudWithMessage(L10n.restoringWallet)
        DispatchQueue.global().async {
            do {
                let account = try SolanaSDK.Account(phrase: self.phrases, network: Defaults.network.cluster)
                try AccountStorage.shared.save(account)
                DispatchQueue.main.async {
                    UIApplication.shared.hideHud()
                    UIApplication.shared.changeRootVC(to: SSPinCodeVC(), withNaviationController: true)
                }
            } catch {
                DispatchQueue.main.async {
                    UIApplication.shared.hideHud()
                    self.showError(error)
                }
            }
        }
    }
}

@available(iOS 13, *)
struct WelcomeBackVC_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UIViewControllerPreview {
                WelcomeBackVC(phrases: [])
            }
            .previewDevice("iPhone SE (2nd generation)")
        }
    }
}
