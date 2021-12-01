//
//  NewOrcaSwap.RootView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 30.11.2021.
//

import UIKit
import RxSwift

extension NewOrcaSwap {
    final class RootView: BEView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        private let viewModel: OrcaSwapV2ViewModelType
        
        // MARK: - Subviews
        private lazy var navigationBar = NavigationBar(
            backHandler: { [weak viewModel] in
                viewModel?.navigate(to: .back)
            },
            settingsHandler: { [weak viewModel] in
                viewModel?.navigate(to: .settings)
            }
        )
        private let mainView: OrcaSwapV2.MainSwapView
        
        // MARK: - Methods
        init(viewModel: OrcaSwapV2ViewModelType) {
            self.viewModel = viewModel
            mainView = .init(viewModel: viewModel)

            super.init(frame: .zero)
        }

        override func commonInit() {
            super.commonInit()
            layout()
            bind()
        }

        // MARK: - Layout
        private func layout() {
            addSubviews()

            navigationBar.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)

            mainView.autoPinEdge(.top, to: .bottom, of: navigationBar, withOffset: 8)
            mainView.autoPinEdge(toSuperviewEdge: .leading, withInset: 18)
            mainView.autoPinEdge(toSuperviewEdge: .trailing, withInset: 18)

        }

        private func addSubviews() {
            addSubview(navigationBar)
            addSubview(mainView)
        }
        
        private func bind() {
            
        }
    }
}
