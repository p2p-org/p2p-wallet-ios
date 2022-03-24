//
//  SelectRecipient.RecipientCell.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 24.10.2021.
//

import BECollectionView
import UIKit

extension SendToken.ChooseRecipientAndNetwork.SelectAddress {
    final class RecipientCell: UICollectionViewCell, BECollectionViewCell {
        private let recipientView = RecipientView()

        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubviews()
            setConstraints()
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
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
            guard let recipient = item as? SendToken.Recipient else { return }
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
