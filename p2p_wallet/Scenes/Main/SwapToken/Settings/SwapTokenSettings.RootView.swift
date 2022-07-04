//
//  SwapTokenSettings.RootView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 21.12.2021.
//

import RxSwift
import UIKit

extension SwapTokenSettings {
    final class RootView: BEView {
        // MARK: - Subviews

        private let significantView: SignificantView

        init(viewModel: NewSwapTokenSettingsViewModelType) {
            significantView = SignificantView(viewModel: viewModel)
            super.init(frame: .zero)
        }

        // MARK: - Methods

        override func commonInit() {
            super.commonInit()

            layout()
        }

        // MARK: - Layout

        private func layout() {
            addSubview(significantView)

            significantView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
            significantView.autoPinEdge(toSuperviewSafeArea: .top)
        }
    }
}
