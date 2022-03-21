//
//  SwapTokenSettings.FeesView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 24.12.2021.
//

import BEPureLayout
import UIKit

extension SwapTokenSettings {
    final class FeesView: BECompositionView {
        private let viewModel: NewSwapTokenSettingsViewModelType

        init(viewModel: NewSwapTokenSettingsViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }

        override func build() -> UIView {
            BEVStack(spacing: 8) {
                // Title
                UILabel(
                    text: L10n.paySwapFeesWith.uppercased(),
                    textSize: 12,
                    textColor: .h8e8e93
                ).padding(.init(only: .left, inset: 18))

                // Fee table
                FeesTable(cellsContentDriver: viewModel.feesContentDriver)
            }
        }
    }
}
