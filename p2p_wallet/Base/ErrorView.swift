//
//  ErrorView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/11/2020.
//

import Foundation
import Action

class ErrorView: BEView {
    lazy var stackView = UIStackView(axis: .vertical, spacing: 8, alignment: .center, distribution: .fill)
    lazy var titleLabel = UILabel(text: L10n.error.uppercaseFirst, textSize: 17, weight: .semibold, textAlignment: .center)
    lazy var descriptionLabel = UILabel(text: L10n.somethingWentWrongPleaseTryAgainLater, textSize: 17, textColor: .secondary, numberOfLines: 0, textAlignment: .center)
    lazy var tryAgainButton = WLButton.stepButton(type: .main, label: L10n.tryAgain)
    
    override func commonInit() {
        super.commonInit()
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
        
        let iconView: UILabel = {
            let label = UILabel(text: "!", textSize: 50, weight: .medium, textAlignment: .center)
            label.backgroundColor = .background
            label.autoSetDimension(.width, toSize: 80)
            label.autoSetDimension(.height, toSize: 80)
            label.layer.cornerRadius = 40
            label.layer.masksToBounds = true
            return label
        }()
        
        stackView.addArrangedSubviews([
            iconView,
            titleLabel,
            descriptionLabel,
            tryAgainButton
        ])
        
        stackView.setCustomSpacing(56.adaptiveHeight, after: iconView)
        stackView.setCustomSpacing(8, after: titleLabel)
        stackView.setCustomSpacing(56.adaptiveHeight, after: descriptionLabel)
        
        tryAgainButton.isHidden = true
    }
    
    var tryAgainAction: CocoaAction? {
        didSet {
            guard let action = tryAgainAction else {
                tryAgainButton.isHidden = true
                return
            }
            tryAgainButton.isHidden = false
            tryAgainButton.rx.action = action
        }
    }
    
    func setUpWithError(_ error: Error) {
        descriptionLabel.text = error.localizedDescription + "\n" + L10n.pleaseTryAgainLater.uppercaseFirst
    }
}
