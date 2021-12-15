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
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Properties
        private let viewModel: OrcaSwapV2ConfirmSwappingViewModelType
        
        // MARK: - Subviews
        private lazy var navigationBar: WLNavigationBar = {
            let navigationBar = WLNavigationBar(forAutoLayout: ())
            navigationBar.backButton.onTap(self, action: #selector(back))
            return navigationBar
        }()
        
        private lazy var rootView = RootView(viewModel: viewModel)
        
        // MARK: - Methods
        init(viewModel: OrcaSwapV2ConfirmSwappingViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
        override func setUp() {
            super.setUp()
            view.addSubview(navigationBar)
            navigationBar.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
            
            view.addSubview(rootView)
            rootView.autoPinEdge(.top, to: .bottom, of: navigationBar, withOffset: 8)
            rootView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
        }
        
        override func bind() {
            super.bind()
            // navigation bar
            Driver.combineLatest(
                viewModel.sourceWalletDriver,
                viewModel.destinationWalletDriver
            )
                .map {source, destination in
                    L10n.confirmSwapping(source?.token.symbol ?? "", destination?.token.symbol ?? "")
                }
                .drive(navigationBar.titleLabel.rx.text)
                .disposed(by: disposeBag)
        }
    }
}
