//
//  WellDoneVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation
import SwiftUI

class WellDoneVC: SecuritySettingVC {
    override func setUp() {
        super.setUp()
        titleLabel.text = L10n.wellDone
        descriptionLabel.text = L10n.exploreP2PWalletAndDepositFundsWhenYouReReady
        
        acceptButton.setTitle(L10n.finishSetup, for: .normal)
        doThisLaterButton.alpha = 0
    }
    
    override func buttonAcceptDidTouch() {
        AppDelegate.shared.reloadRootVC()
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
