//
//  SwapTokenSettings.RootView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 21.12.2021.
//

import UIKit
import RxSwift

extension SwapTokenSettings {
    final class RootView: BEView {
        // MARK: - Constants
        let disposeBag = DisposeBag()

        // MARK: - Properties
        private let viewModel: NewSwapTokenSettingsViewModelType

        // MARK: - Subviews
        private let navigationBar: NavigationBar
        private let slippageView: SlippageView
        private let feesView: FeesView
        private let scrollView = ContentHuggingScrollView(scrollableAxis: .vertical, contentInset: .init(only: .bottom, inset: 40))
        private let stackView = UIStackView(axis: .vertical, spacing: 36, alignment: .fill)

        init(viewModel: NewSwapTokenSettingsViewModelType) {
            self.viewModel = viewModel

            navigationBar = NavigationBar(
                backHandler: { [weak viewModel] in
                    viewModel?.goBack()
                }
            )
            slippageView = SlippageView(viewModel: viewModel)
            feesView = FeesView(viewModel: viewModel)

            super.init(frame: .zero)

            scrollView.showsVerticalScrollIndicator = false
        }
        // MARK: - Methods
        override func commonInit() {
            super.commonInit()

            layout()
        }

        // MARK: - Layout
        private func layout() {
            addSubview(navigationBar)
            addSubview(scrollView)
            stackView.addArrangedSubviews {
                slippageView
                feesView
            }
            scrollView.addSubview(stackView)

            navigationBar.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)

            scrollView.autoPinEdge(.top, to: .bottom, of: navigationBar, withOffset: 18)
            scrollView.autoPinEdge(toSuperviewEdge: .leading)
            scrollView.autoPinEdge(toSuperviewEdge: .trailing)
            scrollView.autoPinBottomToSuperViewAvoidKeyboard()

            stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 18, y: 0))
        }
    }
}
