//
//  IntroVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation

class IntroVC: BaseVC, BEPageVCType {
    var index: Int {0}
    
    // MARK: - Subviews
    lazy var stackView = UIStackView(axis: .vertical, spacing: 31, alignment: .center, distribution: .fill)
    
    lazy var titleLabel = UILabel(text: L10n.wowletForPeopleNotForTokens, textSize: 32, weight: .bold, numberOfLines: 0, textAlignment: .center)
    
    lazy var descriptionLabel = UILabel(textSize: 17, weight: .medium, textColor: UIColor.textBlack.withAlphaComponent(0.6), numberOfLines: 0, textAlignment: .center)
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        
        view.addSubview(stackView)
        stackView.autoPinEdge(toSuperviewEdge: .leading, withInset: 30)
        stackView.autoPinEdge(toSuperviewEdge: .trailing, withInset: 30)
        stackView.autoPinEdge(toSuperviewSafeArea: .top)
        stackView.autoPinEdge(toSuperviewSafeArea: .bottom, withInset: 16)
        
        let spacer1 = UIView.spacer
        stackView.addArrangedSubview(spacer1)
        
        let imageView = UIImageView(width: 219, height: 209)
        imageView.image = .walletIntro
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(titleLabel)
        
//        descriptionLabel.text = "For athletes, high altitude produces two contradictory effects on performance. For explosive events (sprints up to 400 metres, long jump, triple jump) the reduction in atmospheric pressure means there is"
        stackView.addArrangedSubview(descriptionLabel)
        
        let spacer2 = UIView.spacer
        stackView.addArrangedSubview(spacer2)
        
        spacer1.heightAnchor.constraint(equalTo: spacer2.heightAnchor).isActive = true
    }
    
    #if DEBUG
    override func injected() {
        stackView.arrangedSubviews.forEach {$0.removeFromSuperview()}
        super.injected()
    }
    #endif
}

class IntroVCWithButtons: IntroVC {
    lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill)
        return stackView
    }()
    
    override func setUp() {
        super.setUp()
        descriptionLabel.isHidden = false
        stackView.addArrangedSubview(buttonStackView)
        buttonStackView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -60)
            .isActive = true
    }
}
