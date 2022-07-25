//
//  PhoneCodeCellSeparatorView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/07/2022.
//

import BECollectionView_Combine
import Foundation
import KeyAppUI

final class PhoneCodeCellSeparatorView: BECollectionViewDefaultSeparatorView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        let view = UIView(backgroundColor: Asset.Colors.listSeparator.color)
        addSubview(view)
        view.autoPinEdgesToSuperviewEdges(with: .init(x: 20, y: 0))
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
