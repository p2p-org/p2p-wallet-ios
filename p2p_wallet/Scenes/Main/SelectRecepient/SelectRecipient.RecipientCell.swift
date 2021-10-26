//
//  SelectRecipient.RecipientCell.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 24.10.2021.
//

import UIKit

extension SelectRecipient {
    final class RecipientCell: UITableViewCell {
        static let cellIdentifier = "RecipientCell"
        private let recipientView = RecipientView()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)

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
            let constraints = [
                recipientView.autoAlignAxis(toSuperviewAxis: .horizontal),
                recipientView.autoPinEdge(toSuperviewEdge: .leading),
                recipientView.autoPinEdge(toSuperviewEdge: .trailing)
            ]

            NSLayoutConstraint.activate(constraints)
        }
    }
}
