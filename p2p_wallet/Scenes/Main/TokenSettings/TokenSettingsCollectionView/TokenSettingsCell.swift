//
//  TokenSettingsCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/02/2021.
//

import Action
import BECollectionView
import Foundation

protocol TokenSettingsCellDelegate: AnyObject {
    func tokenSettingsCellDidToggleVisibility(_ cell: TokenSettingsCell)
}

class TokenSettingsCell: BaseCollectionViewCell {
    override var padding: UIEdgeInsets { .init(x: 20, y: 14) }

    // MARK: - Subviews

    lazy var iconImageView = UIImageView(width: 24, height: 24, image: .buttonEdit, tintColor: .iconSecondary)
    lazy var descriptionLabel = UILabel(textSize: 13, weight: .semibold, textColor: .textSecondary)
    lazy var mainLabel = UILabel(textSize: 17, weight: .semibold)
    lazy var isVisibleSwitcher = UISwitch()

    // MARK: - Actions

    weak var delegate: TokenSettingsCellDelegate?

    override func commonInit() {
        super.commonInit()
        stackView.axis = .horizontal
        stackView.spacing = 16

        stackView.addArrangedSubviews {
            iconImageView
                .padding(.init(all: 10), backgroundColor: .grayPanel, cornerRadius: 12)
            UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill, arrangedSubviews: [
                descriptionLabel,
                mainLabel,
            ])
            isVisibleSwitcher
        }

        let separator = UIView.separator(height: 1, color: .clear.onDarkMode(.separator))
        addSubview(separator)
        separator.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)

        isVisibleSwitcher.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
    }

    @objc func switchChanged(_: UISwitch) {
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
        iconImageView.tintColor = .iconSecondary
        stackView.alpha = 1
        switch item {
        case let .visibility(isVisible):
            isVisibleSwitcher.isHidden = false
            iconImageView.image = isVisible ? .visibilityShow : .visibilityHide
            descriptionLabel.text = L10n.visibilityInTokenList
            mainLabel.text = isVisible ? L10n.visible : L10n.hidden
            isVisibleSwitcher.isOn = isVisible
        case let .close(isEnabled):
            iconImageView.image = .closeToken
            iconImageView.tintColor = .alert
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
