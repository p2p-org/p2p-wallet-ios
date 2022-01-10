//
//  SwapTokenSettings.FeesView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 24.12.2021.
//

import BEPureLayout
import UIKit

extension SwapTokenSettings {
    final class FeesView: UIStackView {
        private let title = UILabel(
            text: L10n.paySwapFeesWith.uppercased(),
            textSize: 12,
            textColor: .h8e8e93
        )
        private let feesTable = FeesTable()
        private let viewModel: NewSwapTokenSettingsViewModelType

        init(viewModel: NewSwapTokenSettingsViewModelType) {
            self.viewModel = viewModel
            
            super.init(frame: .zero)

            configureSelf()
            layout()
        }

        @available(*, unavailable)
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func configureSelf() {
            axis = .vertical
            spacing = 8
        }

        private func layout() {
            let allSubviews = [title, feesTable]
            allSubviews.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

            addArrangedSubviews {
                title.padding(.init(only: .left, inset: 18))
                feesTable
            }

            feesTable.setUp(cellsContent: viewModel.feesContent)

        }
    }
}
