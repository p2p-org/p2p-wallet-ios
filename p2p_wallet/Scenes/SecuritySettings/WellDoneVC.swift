//
//  WellDoneVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation
import SwiftUI

class WellDoneVC: SecuritySettingVC {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    override func setUp() {
        super.setUp()
        // add child
        let vc = _WellDoneVC()
        acceptButton.setTitle(L10n.finishSetup, for: .normal)
        vc.finishButton = acceptButton
        addChild(vc)
        vc.view.configureForAutoLayout()
        view.addSubview(vc.view)
        vc.view.autoPinEdgesToSuperviewEdges()
        vc.didMove(toParent: self)
    }
    
    override func buttonAcceptDidTouch() {
        AppDelegate.shared.reloadRootVC()
    }
}

class _WellDoneVC: WLIntroVC {
    weak var finishButton: UIButton?
    override func setUp() {
        super.setUp()
        titleLabel.text = L10n.wellDone
        descriptionLabel.text = L10n.exploreP2PWalletAndDepositFundsWhenYouReReady
        buttonsStackView.addArrangedSubviews([
            finishButton,
            UIView(height: 56)
        ])
    }
}

@available(iOS 13, *)
struct WellDoneVC_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UIViewControllerPreview {
                WellDoneVC()
            }
            .previewDevice("iPhone SE (2nd generation)")
        }
    }
}
