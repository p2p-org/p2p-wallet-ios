//
//  BaseOnboardingVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 20/02/2021.
//

import Foundation

class BaseOnboardingVC: BaseVStackVC {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
        .hidden
    }
    override var padding: UIEdgeInsets {.zero}
    lazy var titleLabel = UILabel(text: L10n.almostDone, textSize: 21, weight: .semibold)
    lazy var imageView = UIImageView(width: 44, height: 44)
    let spacer1 = UIView.spacer
    lazy var firstDescriptionLabel = UILabel(textSize: 21, weight: .semibold, numberOfLines: 0, textAlignment: .center)
    lazy var secondDescriptionLabel = UILabel(textSize: 17, textColor: .textSecondary, numberOfLines: 0, textAlignment: .center)
    let spacer2 = UIView.spacer
    lazy var acceptButton = WLButton.stepButton(type: .blue, label: nil)
        .onTap(self, action: #selector(buttonAcceptDidTouch))
    lazy var doThisLaterButton = WLButton.stepButton(type: .gray, label: L10n.doThisLater)
        .onTap(self, action: #selector(buttonDoThisLaterDidTouch))
    
    lazy var buttonsStackView = UIStackView(axis: .vertical, spacing: 16, alignment: .fill, distribution: .fill)
    
    override func setUp() {
        super.setUp()
        stackView.spacing = 0
        
        stackView.addArrangedSubviews([
            titleLabel.padding(.init(all: 20)),
            UIView.separator(height: 1, color: .separator),
            spacer1,
            imageView
                .padding(.init(all: 18), backgroundColor: .grayPanel.withAlphaComponent(0.5), cornerRadius: 12)
                .centeredHorizontallyView,
            BEStackViewSpacing(30),
            firstDescriptionLabel.padding(.init(x: 20, y: 0)),
            BEStackViewSpacing(15),
            secondDescriptionLabel.padding(.init(x: 20, y: 0)),
            spacer2,
            buttonsStackView.padding(.init(x: 20, y: 0))
        ])
        
        buttonsStackView.addArrangedSubviews([
            acceptButton,
            doThisLaterButton
        ])
        spacer1.heightAnchor.constraint(equalTo: spacer2.heightAnchor)
            .isActive = true
        scrollView.contentView.autoPinBottomToSuperViewSafeAreaAvoidKeyboard(inset: 16)
    }
    
    @objc func buttonAcceptDidTouch() {
    }
    
    @objc func buttonDoThisLaterDidTouch() {
    }
}
