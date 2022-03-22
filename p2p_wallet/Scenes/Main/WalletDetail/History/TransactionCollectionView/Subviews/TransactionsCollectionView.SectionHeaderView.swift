//
//  TransactionsCollectionView.SectionHeaderView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/07/2021.
//

import Foundation

extension TransactionsCollectionView {
    class SectionHeaderView: BaseCollectionReusableView {
        override var padding: UIEdgeInsets { .init(x: 20, y: 0) }
        private lazy var dateLabel = UILabel(text: "Date", textSize: 15, weight: .medium, textColor: .textSecondary)
        override func commonInit() {
            super.commonInit()
            stackView.addArrangedSubview(dateLabel.padding(.init(only: .top, inset: 20)))
        }

        func setUp(header: String?) {
            dateLabel.superview?.isHidden = header == nil
            dateLabel.text = header
        }
    }
}
