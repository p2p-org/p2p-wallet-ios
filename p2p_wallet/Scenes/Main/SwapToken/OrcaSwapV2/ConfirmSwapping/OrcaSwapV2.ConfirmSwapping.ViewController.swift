//
//  OrcaSwapV2.ConfirmViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/12/2021.
//

import Combine
import Foundation

extension OrcaSwapV2.ConfirmSwapping {
    final class ViewController: BaseVC {
        // MARK: - Properties

        private let viewModel: OrcaSwapV2ConfirmSwappingViewModelType
        private var subscriptions = [AnyCancellable]()

        // MARK: - Subviews

        private lazy var rootView = RootView(viewModel: viewModel)

        // MARK: - Methods

        init(viewModel: OrcaSwapV2ConfirmSwappingViewModelType) {
            self.viewModel = viewModel
            super.init()
        }

        override func loadView() {
            view = rootView
        }

        override func bind() {
            super.bind()
            // navigation bar
            Publishers.CombineLatest(
                viewModel.sourceWalletPublisher,
                viewModel.destinationWalletPublisher
            )
                .map { source, destination in
                    L10n.confirmSwapping(source?.token.symbol ?? "", destination?.token.symbol ?? "")
                }
                .sink { [weak self] in
                    self?.navigationItem.title = $0
                }
                .store(in: &subscriptions)
        }
    }
}
