//
//  SwapTokenSettings.SignificantView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 28.12.2021.
//

import UIKit

extension SwapTokenSettings {
    final class SignificantView: ScrollableVStackRootView {
        // MARK: - Properties

        private let viewModel: NewSwapTokenSettingsViewModelType

        // MARK: - Subviews

        private let slippageView: SlippageView
        private let feesView: FeesView

        init(viewModel: NewSwapTokenSettingsViewModelType) {
            self.viewModel = viewModel

            slippageView = SlippageView(viewModel: viewModel)
            feesView = FeesView(viewModel: viewModel)

            super.init(frame: .zero)

            stackView.spacing = 36
            scrollView.showsVerticalScrollIndicator = false
        }

        // MARK: - Methods

        override func commonInit() {
            super.commonInit()

            layout()
        }

        // MARK: - Layout

        private func layout() {
            stackView.addArrangedSubviews {
                slippageView
                feesView
            }
        }
    }
}
