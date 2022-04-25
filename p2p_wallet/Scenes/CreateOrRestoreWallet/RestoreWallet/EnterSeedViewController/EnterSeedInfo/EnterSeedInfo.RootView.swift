//
//  EnterSeedInfo.RootView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 18.11.2021.
//

import RxSwift
import UIKit

extension EnterSeedInfo {
    class RootView: BEView {
        // MARK: - Dependencies

        private let viewModel: EnterSeedInfoViewModelType

        // MARK: - Subviews

        lazy var scrollView = ContentHuggingScrollView(
            scrollableAxis: .vertical,
            contentInset: .init(only: .bottom, inset: 40)
        )
        lazy var stackView = UIStackView(axis: .vertical, spacing: 18, alignment: .fill, distribution: .fill)
        private let firstTitle = UILabel(
            text: L10n.theDefinition,
            textSize: 28,
            weight: .bold
        )
        private let firstDescription = UILabel(
            text: L10n.youCanCompareACryptocurrencyWallet,
            textSize: 17,
            numberOfLines: 0
        )
        private let firstOptions: UIView = .greyBannerView {
            UILabel(
                text: L10n.ifLostNoOneCanRestoreItKeepItPrivateEvenFromUs,
                textSize: 15,
                numberOfLines: 0
            )
        }

        private let secondTitle = UILabel(
            text: L10n.whereCanIFindOne,
            textSize: 28,
            weight: .bold
        )
        private let secondDescription = UILabel(
            text: L10n.ifYouCreateANewWalletAccount,
            textSize: 17,
            numberOfLines: 0
        )

        // MARK: - Methods

        init(viewModel: EnterSeedInfoViewModelType) {
            self.viewModel = viewModel

            super.init(frame: .zero)
        }

        override func commonInit() {
            super.commonInit()
            layout()
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
        }

        // MARK: - Layout

        private func layout() {
            let navigationBar = NavigationBar(doneHandler: { [weak self] in
                self?.viewModel.done()
            })
            let headerView = UIView()
            headerView.addSubview(navigationBar)
            headerView.frame = navigationBar.frame
            navigationBar.autoPinEdgesToSuperviewEdges(with: .init(only: .top, inset: 14))
            headerView.backgroundColor = .fafafc
            addSubview(headerView)
            headerView.autoPinEdgesToSuperviewEdges(with: .init(only: .top, inset: 0), excludingEdge: .bottom)

            // Navigation separator
            let separator = UIView.defaultSeparator()
            addSubview(separator)
            separator.autoPinEdge(.top, to: .bottom, of: navigationBar)
            separator.autoPinEdge(toSuperviewEdge: .leading)
            separator.autoPinEdge(toSuperviewEdge: .trailing)

            addSubview(scrollView)
            scrollView.contentView.addSubview(stackView)

            scrollView.autoPinEdge(.top, to: .bottom, of: navigationBar, withOffset: 24)
            scrollView.autoPinEdge(toSuperviewEdge: .leading)
            scrollView.autoPinEdge(toSuperviewEdge: .trailing)
            scrollView.autoPinBottomToSuperViewSafeAreaAvoidKeyboard()

            stackView.addArrangedSubviews {
                firstTitle
                firstDescription
                firstOptions
                secondTitle
                secondDescription
            }

            stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 20, y: 0))
        }
    }
}
