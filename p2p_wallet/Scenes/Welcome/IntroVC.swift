//
//  IntroVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation

class IntroVC: BaseVC {
    
    // MARK: - Subviews
    lazy var stackView = UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill)
    
    lazy var titleLabel = UILabel(text: "Wowlet", textSize: 32, weight: .bold, textColor: .white, numberOfLines: 0, textAlignment: .center)
    
    lazy var descriptionLabel = UILabel(textSize: 17, weight: .medium, textColor: UIColor.white.withAlphaComponent(0.6), numberOfLines: 0, textAlignment: .center)
    
    lazy var iconView = createIconView()
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        view.backgroundColor = .black
        
        view.addSubview(stackView)
        stackView.autoPinEdge(toSuperviewEdge: .leading)
        stackView.autoPinEdge(toSuperviewEdge: .trailing)
        stackView.autoPinEdge(toSuperviewSafeArea: .top)
        stackView.autoPinEdge(toSuperviewSafeArea: .bottom, withInset: 16)
        
        let spacer1 = UIView.spacer
        let spacer2 = UIView.spacer
        stackView.addArrangedSubviews([
            UIImageView(width: 88, height: 31, image: .p2pValidatorLogo)
                .centeredHorizontallyView,
            spacer1,
            iconView.centeredHorizontallyView,
            titleLabel.padding(.init(x: 30, y: 0)),
            descriptionLabel.padding(.init(x: 30, y: 0)),
            spacer2
        ])
        
        stackView.setCustomSpacing(50.adaptiveHeight, after: iconView.wrapper!)
        
        spacer1.heightAnchor.constraint(
            equalTo: spacer2.heightAnchor
        )
            .isActive = true
        
        descriptionLabel.text = L10n.secureNonCustodialBankOfFuture + "\n" + L10n.simpleFinanceForEveryone
    }
    
    func createIconView() -> UIView {
        UIView(height: 0)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}

class IntroVCWithButtons: IntroVC {
    lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill)
        return stackView
    }()
    
    override func setUp() {
        super.setUp()
        descriptionLabel.isHidden = false
        stackView.addArrangedSubview(buttonStackView.centeredHorizontallyView)
        buttonStackView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -60)
            .isActive = true
    }
}
