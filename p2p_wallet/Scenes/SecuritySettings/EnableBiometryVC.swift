//
//  EnableBiometryVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation

class EnableBiometryVC: BaseVC {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {.hidden}
    
    lazy var stackView = UIStackView(axis: .vertical, spacing: 36, alignment: .center, distribution: .fill)
    
    lazy var useFaceIdButton = WLButton.stepButton(type: .main, label: L10n.useFaceId)
    
    lazy var doThisLaterButton = WLButton.stepButton(type: .sub, label: L10n.doThisLater)
    
    override func setUp() {
        super.setUp()
        view.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewSafeArea(with: UIEdgeInsets(top: 0, left: 20, bottom: 16, right: 20))
        
        let label = UILabel(text: L10n.useYourFaceIDForQuickAccess, textSize: 21, weight: .medium, numberOfLines: 0, textAlignment: .center)
        let imageView = UIImageView(width: 64, height: 64, image: .faceId)
        let spacer1 = UIView.spacer
        let spacer2 = UIView.spacer
        
        stackView.addArrangedSubview(spacer1)
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(spacer2)
        
        spacer1.heightAnchor.constraint(equalTo: spacer2.heightAnchor).isActive = true
        
        let buttonStackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill)
        buttonStackView.addArrangedSubview(useFaceIdButton)
        buttonStackView.addArrangedSubview(doThisLaterButton)
        stackView.addArrangedSubview(buttonStackView)
        buttonStackView.widthAnchor.constraint(equalTo: stackView.widthAnchor, constant: -40)
            .isActive = true
    }
}
