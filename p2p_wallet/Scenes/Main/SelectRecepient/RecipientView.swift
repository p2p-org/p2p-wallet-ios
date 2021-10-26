//
//  RecipientView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 25.10.2021.
//

import UIKit
import BEPureLayout

final class RecipientView: UIStackView {
    private let recipientIcon = UIImageView()
    private let textFieldsStackView = UIStackView(
        axis: .vertical,
        spacing: 8,
        alignment: .leading,
        distribution: .equalSpacing
    )
    private let recipientName = UILabel(textSize: 17, weight: .semibold, textColor: .black)
    private let recipientAddress = UILabel(textSize: 15, weight: .regular, textColor: .a3a5ba)

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
        recipientName.isHidden = recipient.name == nil
        recipientName.text = recipient.name
        recipientAddress.text = recipient.shortAddress
    }

    private func configureSelf() {
        axis = .horizontal
        spacing = 15
        alignment = .center
        distribution = .fill
    }

    private func configureSubviews() {
        recipientIcon.image = .emptyUserAvatar
        [recipientName, recipientAddress].forEach(textFieldsStackView.addArrangedSubview)
    }

    private func addSubviews() {
        [recipientIcon, textFieldsStackView].forEach(addArrangedSubview)
    }

    private func setConstraints() {
        recipientIcon.autoSetDimensions(to: CGSize(width: 45, height: 45))
    }
}
