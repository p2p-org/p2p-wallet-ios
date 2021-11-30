//
//  SelectRecipient.RecipientCell.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 24.10.2021.
//

import UIKit
import BECollectionView

extension SendToken.ChooseRecipientAndNetwork.SelectAddress {
    final class RecipientCell: UICollectionViewCell, BECollectionViewCell {
        private let recipientView = RecipientView()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubviews()
            setConstraints()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func setRecipient(_ recipient: Recipient) {
            recipientView.setRecipient(recipient)
        }

        private func addSubviews() {
            [recipientView].forEach(addSubview)
        }

        private func setConstraints() {
            recipientView.autoAlignAxis(toSuperviewAxis: .horizontal)
            recipientView.autoPinEdge(toSuperviewEdge: .leading, withInset: 20)
            recipientView.autoPinEdge(toSuperviewEdge: .trailing, withInset: 20)
        }
        
        // MARK: - BECollectionViewCell implementation
        func setUp(with item: AnyHashable?) {
            guard let recipient = item as? Recipient else {return}
            recipientView.setRecipient(recipient)
        }
        
        func hideLoading() {
            recipientView.hideLoader()
        }
        
        func showLoading() {
            recipientView.showLoader()
        }
    }
}

final class RecipientView: UIStackView {
    private let recipientIcon = UIImageView()
    private let textFieldsStackView = UIStackView(
        axis: .vertical,
        spacing: 8,
        alignment: .leading,
        distribution: .equalSpacing
    )
    private let titleLabel = UILabel(text: "<recipientName>", textSize: 17, weight: .semibold)
    private let descriptionLabel: UILabel = {
        let label = UILabel(text: "<recipientAddress>", textSize: 15, weight: .regular, textColor: .a3a5ba)
        label.lineBreakMode = .byTruncatingMiddle
        return label
    }()

    init() {
        super.init(frame: .zero)

        configureSelf()
        configureSubviews()
        addSubviews()
        setConstraints()
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setRecipient(_ recipient: Recipient) {
        titleLabel.text = recipient.name ?? recipient.address.truncatingMiddle(numOfSymbolsRevealed: 13, numOfSymbolsRevealedInSuffix: 4)
        if recipient.name == nil {
            descriptionLabel.isHidden = !recipient.hasNoFunds
            descriptionLabel.text = L10n.thisAddressHasNoFunds
        } else {
            descriptionLabel.isHidden = false
            descriptionLabel.text = recipient.address
        }
    }

    private func configureSelf() {
        axis = .horizontal
        spacing = 12
        alignment = .center
        distribution = .fill
    }

    private func configureSubviews() {
        recipientIcon.image = .emptyUserAvatar
        [titleLabel, descriptionLabel].forEach(textFieldsStackView.addArrangedSubview)
    }

    private func addSubviews() {
        [recipientIcon, textFieldsStackView].forEach(addArrangedSubview)
    }

    private func setConstraints() {
        recipientIcon.autoSetDimensions(to: CGSize(width: 45, height: 45))
    }
}
