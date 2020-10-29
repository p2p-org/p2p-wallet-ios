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
    
    lazy var descriptionLabel = UILabel(text: "For athletes, high altitude produces two contradictory effects on performance. For explosive events (sprints up to 400 metres, long jump, triple jump) the reduction in atmospheric pressure means there is", textSize: 17, weight: .medium, textColor: UIColor.textBlack.withAlphaComponent(0.6), numberOfLines: 0, textAlignment: .center)
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        
        let imageView = UIImageView(width: 220, height: 220, cornerRadius: 110)
        imageView.image = .walletIntro
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(titleLabel)
        
        // FIXME: - Change text
        stackView.addArrangedSubview(descriptionLabel)
        
        view.addSubview(stackView)
        stackView.autoCenterInSuperview()
        stackView.autoPinEdge(toSuperviewEdge: .leading, withInset: 30)
        stackView.autoPinEdge(toSuperviewEdge: .trailing, withInset: 30)
    }
    
    #if DEBUG
    override func injected() {
        stackView.arrangedSubviews.forEach {$0.removeFromSuperview()}
        super.injected()
    }
    #endif
}
