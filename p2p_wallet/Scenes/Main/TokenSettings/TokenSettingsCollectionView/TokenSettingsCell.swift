//
//  TokenSettingsCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/02/2021.
//

import Foundation
import Action

class TokenSettingsCell: ListCollectionCell<TokenSettings> {
    // MARK: - Subviews
    lazy var iconImageView = UIImageView(width: 24, height: 24, image: .buttonEdit, tintColor: .a3a5ba)
    lazy var descriptionLabel = UILabel(textSize: 13, weight: .semibold, textColor: .textSecondary)
    lazy var mainLabel = UILabel(textSize: 17, weight: .semibold)
    lazy var isVisibleSwitcher = UISwitch()
    
    // MARK: - Actions
    var toggleVisibilityAction: CocoaAction?
    
    override func commonInit() {
        super.commonInit()
        backgroundColor = .textWhite
        let stackView = UIStackView(axis: .horizontal, spacing: 16, alignment: .fill, distribution: .fill, arrangedSubviews: [
            iconImageView
                .padding(.init(all: 10), backgroundColor: .f6f6f8, cornerRadius: 12),
            UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill, arrangedSubviews: [
                descriptionLabel,
                mainLabel
            ]),
            isVisibleSwitcher
        ])
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 20, y: 14))
        
        isVisibleSwitcher.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
    }
    
    override func setUp(with item: TokenSettings) {
        descriptionLabel.isHidden = false
        isVisibleSwitcher.isHidden = true
        switch item {
        case .visibility(let isVisible):
            isVisibleSwitcher.isHidden = false
            iconImageView.image = isVisible ? .visibilityShow: .visibilityHide
            descriptionLabel.text = L10n.visibilityInTokenList
            mainLabel.text = isVisible ? L10n.visible: L10n.hidden
            isVisibleSwitcher.isOn = isVisible
        case .close:
            iconImageView.image = .closeToken
            descriptionLabel.isHidden = true
            mainLabel.text = L10n.closeTokenAccount
        }
    }
    
    @objc func switchChanged(_ mySwitch: UISwitch) {
        toggleVisibilityAction?.execute()
    }
}
