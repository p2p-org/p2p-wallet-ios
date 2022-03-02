//
//  SwapTokenSettings.SeparatorView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 27.12.2021.
//

import BEPureLayout

extension SwapTokenSettings {
    final class SeparatorView: BEView {
        private let lineView = UIView(height: 1, backgroundColor: .f2f2f7)

        init() {
            super.init(frame: .zero)

            addSubview(lineView)
            lineView.autoPinEdgesToSuperviewEdges(with: .init(only: .left, inset: 50))
        }
    }
}
