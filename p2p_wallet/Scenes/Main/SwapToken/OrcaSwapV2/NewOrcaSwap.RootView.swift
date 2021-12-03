//
//  NewOrcaSwap.RootView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 30.11.2021.
//

import UIKit
import RxSwift
import RxCocoa

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
        private let showDetailsButton = OrcaSwapV2.ShowDetailsButton()
        
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

            showDetailsButton.autoSetDimension(.height, toSize: 40)
            showDetailsButton.autoPinEdge(.top, to: .bottom, of: mainView, withOffset: 8)
            showDetailsButton.autoPinEdge(toSuperviewEdge: .leading, withInset: 18)
            showDetailsButton.autoPinEdge(toSuperviewEdge: .trailing, withInset: 18)
        }

        private func addSubviews() {
            addSubview(navigationBar)
            addSubview(mainView)
            addSubview(showDetailsButton)
        }
        
        private func bind() {
            viewModel.loadingStateDriver
                .drive(onNext: {[weak self] state in
                    self?.setUp(state, reloadAction: { [weak self] in
                        self?.viewModel.reload()
                    })
                })
                .disposed(by: disposeBag)

            viewModel.isShowingDetailsDriver
                .drive(onNext: {[weak self] state in
                    self?.showDetailsButton.setState(isShown: state)
                })
                .disposed(by: disposeBag)

            showDetailsButton.rx.tap
                .bind(to: viewModel.showHideDetailsButtonTapSubject)
                .disposed(by: disposeBag)

        }
    }
}
