//
//  OrcaSwapV2.ConfirmViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/12/2021.
//

import Foundation
import RxCocoa

extension OrcaSwapV2.ConfirmSwapping {
    final class ViewController: BaseVC {
        // MARK: - Properties

        private let viewModel: OrcaSwapV2ConfirmSwappingViewModelType

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
            Driver.combineLatest(
                viewModel.sourceWalletDriver,
                viewModel.destinationWalletDriver
            )
                .map { source, destination in
                    L10n.confirmSwapping(source?.token.symbol ?? "", destination?.token.symbol ?? "")
                }
                .drive(onNext: { [weak self] in
                    self?.navigationItem.title = $0
                })
                .disposed(by: disposeBag)
        }
    }
}
