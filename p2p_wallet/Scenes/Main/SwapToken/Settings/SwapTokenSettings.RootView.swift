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
        // MARK: - Properties

        private let viewModel: NewSwapTokenSettingsViewModelType

        // MARK: - Subviews

        private let navigationBar: NavigationBar
        private let significantView: SignificantView

        init(viewModel: NewSwapTokenSettingsViewModelType) {
            self.viewModel = viewModel

            navigationBar = NavigationBar(
                backHandler: { [weak viewModel] in
                    viewModel?.goBack()
                }
            )
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
            addSubview(navigationBar)
            addSubview(significantView)

            navigationBar.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)

            significantView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
            significantView.autoPinEdge(.top, to: .bottom, of: navigationBar)
        }
    }
}
