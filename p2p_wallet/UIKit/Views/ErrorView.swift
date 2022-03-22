//
//  ErrorView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/11/2020.
//

import Action
import Foundation

class MessageView: BEView {
    lazy var stackView = UIStackView(axis: .vertical, spacing: 8, alignment: .center, distribution: .fill)
    lazy var titleLabel = UILabel(
        text: L10n.error.uppercaseFirst,
        textSize: 17,
        weight: .semibold,
        textAlignment: .center
    )
    lazy var descriptionLabel = UILabel(
        text: L10n.somethingWentWrongPleaseTryAgainLater,
        textSize: 17,
        textColor: .textSecondary,
        numberOfLines: 0,
        textAlignment: .center
    )
    lazy var actionButton = WLButton.stepButton(type: .black, label: L10n.tryAgain)

    override func commonInit() {
        super.commonInit()
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()

        stackView.addArrangedSubviews([
            titleLabel,
            descriptionLabel,
            actionButton,
        ])
        actionButton.contentEdgeInsets = actionButton.contentEdgeInsets.modifying(dLeft: 16, dRight: 16)
        actionButton.isHidden = true
    }

    var buttonAction: CocoaAction? {
        didSet {
            guard let action = buttonAction else {
                actionButton.isHidden = true
                return
            }
            actionButton.isHidden = false
            actionButton.rx.action = action
        }
    }
}

class ErrorView: MessageView {
    override func commonInit() {
        super.commonInit()

        let iconView: UILabel = {
            let label = UILabel(text: "!", textSize: 50, weight: .medium, textAlignment: .center)
            label.backgroundColor = .background
            label.autoSetDimension(.width, toSize: 80)
            label.autoSetDimension(.height, toSize: 80)
            label.layer.cornerRadius = 40
            label.layer.masksToBounds = true
            return label
        }()

        stackView.insertArrangedSubview(iconView, at: 0)
        stackView.setCustomSpacing(56.adaptiveHeight, after: iconView)
        stackView.setCustomSpacing(8, after: titleLabel)
        stackView.setCustomSpacing(56.adaptiveHeight, after: descriptionLabel)
    }

    func setUpWithError(_ error: Error) {
        let description = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        descriptionLabel.text = description + "\n" + L10n.pleaseTryAgainLater.uppercaseFirst
    }
}
