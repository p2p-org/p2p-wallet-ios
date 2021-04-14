//
//  TokenSettingsCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/02/2021.
//

import Foundation
import Action
import BECollectionView

protocol TokenSettingsCellDelegate: class {
    func tokenSettingsCellDidToggleVisibility(_ cell: TokenSettingsCell)
}

class TokenSettingsCell: BaseCollectionViewCell, LoadableView {
    var loadingViews: [UIView] {[
        iconImageView,
        descriptionLabel,
        mainLabel,
        isVisibleSwitcher
    ]}
    
    // MARK: - Subviews
    lazy var stackView = UIStackView(axis: .horizontal, spacing: 16, alignment: .fill, distribution: .fill, arrangedSubviews: [
        iconImageView
            .padding(.init(all: 10), backgroundColor: .f6f6f8, cornerRadius: 12),
        UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill, arrangedSubviews: [
            descriptionLabel,
            mainLabel
        ]),
        isVisibleSwitcher
    ])
    lazy var iconImageView = UIImageView(width: 24, height: 24, image: .buttonEdit, tintColor: .a3a5ba)
    lazy var descriptionLabel = UILabel(textSize: 13, weight: .semibold, textColor: .textSecondary)
    lazy var mainLabel = UILabel(textSize: 17, weight: .semibold)
    lazy var isVisibleSwitcher = UISwitch()
    
    // MARK: - Actions
    weak var delegate: TokenSettingsCellDelegate?
    
    override func commonInit() {
        super.commonInit()
        backgroundColor = .textWhite
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 20, y: 14))
        
        isVisibleSwitcher.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
    }
    
    @objc func switchChanged(_ mySwitch: UISwitch) {
        delegate?.tokenSettingsCellDidToggleVisibility(self)
    }
}

extension TokenSettingsCell: BECollectionViewCell {
    func setUp(with item: AnyHashable?) {
        guard let item = item as? TokenSettings else {
            return
        }
        descriptionLabel.isHidden = false
        isVisibleSwitcher.isHidden = true
        stackView.alpha = 1
        switch item {
        case .visibility(let isVisible):
            isVisibleSwitcher.isHidden = false
            iconImageView.image = isVisible ? .visibilityShow: .visibilityHide
            descriptionLabel.text = L10n.visibilityInTokenList
            mainLabel.text = isVisible ? L10n.visible: L10n.hidden
            isVisibleSwitcher.isOn = isVisible
        case .close(let isEnabled):
            iconImageView.image = .closeToken
            if isEnabled {
                descriptionLabel.isHidden = true
            } else {
                descriptionLabel.text = L10n.tokenAccountShouldBeZero
                stackView.alpha = 0.5
            }
            mainLabel.text = L10n.closeTokenAccount
        }
    }
}
