//
//  EnableNotificationsVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation

class EnableNotificationsVC: SecuritySettingVC {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {.hidden}
    
    override var nextVC: UIViewController {
        BaseVC()
    }
    
    override func setUp() {
        super.setUp()
        acceptButton.setTitle(L10n.enableNow, for: .normal)
        
        let almostDoneLabel = UILabel(text: L10n.almostDone, textSize: 32, weight: .bold, textAlignment: .center)
        
        let spacer3 = UIView.spacer
        spacer3.autoSetDimension(.height, toSize: 126 - 2*stackView.spacing)
        
        let titleLabel = UILabel(text: L10n.weSuggestYouAlsoToEnablePushNotifications, textSize: 21, weight: .semibold, numberOfLines: 0, textAlignment: .center)
        
        stackView.insertArrangedSubview(almostDoneLabel, at: 1)
        stackView.insertArrangedSubview(spacer3, at: 2)
        stackView.insertArrangedSubview(titleLabel, at: 3)
//        stackView.insertArrangedSubview(UILabel(text: "For athletes, high altitude produces two contradictory effects on performance. For explosive events (sprints up to 400 metres, long jump, triple jump) the reduction in atmospheric pressure means there is", numberOfLines: 0), at: 4)
        
    }
}
