//
//  WellDoneVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation

class WellDoneVC: SecuritySettingVC {
    override var preferredStatusBarStyle: UIStatusBarStyle {.lightContent}
    
    override func setUp() {
        super.setUp()
        // static background color
        view.backgroundColor = .introBgStatic
        
        // lines view
        let linesView = UIImageView(image: .introLinesBg)
        view.addSubview(linesView)
        linesView.autoPinEdgesToSuperviewEdges()
        
        // top logo
        stackView.insertArrangedSubview(
            UIImageView.p2pValidatorLogo
                .centeredHorizontallyView,
            at: 0
        )
        
        // content
        stackView.spacing = 30
        
        acceptButton.removeFromSuperview()
        
        var index = 2
        stackView.insertArrangedSubviewsWithCustomSpacing([
            UILabel(text: L10n.wellDone, font: FontFamily.Montserrat.extraBold.font(size: 32), textColor: .white, textAlignment: .center),
            UILabel(text: L10n.exploreWowletAndDepositFundsWhenYouReReady, textSize: 17, weight: .medium, textColor: UIColor.white.withAlphaComponent(0.6), numberOfLines: 0, textAlignment: .center),
            acceptButton
        ], at: &index)
        
        acceptButton.widthAnchor.constraint(equalTo: stackView.widthAnchor, constant: -40)
            .isActive = true
        
        // bottom button
        doThisLaterButton.isHidden = true
        acceptButton.setTitle(L10n.finishSetup, for: .normal)
        
        // fix spacer
        spacer1.constraint(toRelativeView: spacer2, withAttribute: .height)?
            .isActive = false
        spacer2.heightAnchor.constraint(equalToConstant: 90)
            .isActive = true
    }
    
    override func buttonAcceptDidTouch() {
        AppDelegate.shared.reloadRootVC()
    }
}
