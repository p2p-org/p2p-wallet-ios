//
//  WellDoneVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation

class WellDoneVC: SecuritySettingVC {
    override func setUp() {
        super.setUp()
        acceptButton.setTitle(L10n.finishSetup, for: .normal)
        doThisLaterButton.isHidden = true
        
        stackView.spacing = 30
        
        let imageView = UIImageView(width: 219, height: 209, image: .walletIntro)
        let titleLabel = UILabel(text: L10n.wellDone, textSize: 32, weight: .bold, textAlignment: .center)
        let descriptionLabel = UILabel(text: L10n.exploreWowletAndDepositFundsWhenYouReReady, textSize: 17, weight: .medium, textColor: UIColor.textBlack.withAlphaComponent(0.6), numberOfLines: 0, textAlignment: .center)
        
        stackView.insertArrangedSubview(imageView, at: 1)
        stackView.insertArrangedSubview(titleLabel, at: 2)
        stackView.insertArrangedSubview(descriptionLabel, at: 3)
    }
    
    override func buttonAcceptDidTouch() {
        UIApplication.shared.changeRootVC(to: TabBarVC())
    }
}
