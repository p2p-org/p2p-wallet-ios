//
//  NewOrcaSwap.RootView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 30.11.2021.
//

import UIKit
import RxSwift
import RxCocoa

enum NewOrcaSwap {
    
}

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

        // MARK: - Subviews
        private let scrollView = ContentHuggingScrollView(scrollableAxis: .vertical, contentInset: .init(only: .bottom, inset: 40))
        private let stackView = UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill)
        private lazy var nextButton = WLStepButton.main(image: .check, text: L10n.reviewAndConfirm)
            .onTap(self, action: #selector(buttonNextDidTouch))

        private let mainView: OrcaSwapV2.MainSwapView
        private let showDetailsButton = OrcaSwapV2.ShowDetailsButton()
        private let detailsView: OrcaSwapV2.DetailsView
        
        // MARK: - Methods
        init(viewModel: OrcaSwapV2ViewModelType) {
            self.viewModel = viewModel

            detailsView = .init(viewModel: viewModel)
            mainView = .init(viewModel: viewModel)

            super.init(frame: .zero)
        }

        override func commonInit() {
            super.commonInit()

            scrollView.showsVerticalScrollIndicator = false
            layout()
            bind()
        }

        // MARK: - Layout
        private func layout() {
            addSubviews()

            navigationBar.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)

            scrollView.autoPinEdge(.top, to: .bottom, of: navigationBar, withOffset: 8)
            scrollView.autoPinEdge(toSuperviewEdge: .leading)
            scrollView.autoPinEdge(toSuperviewEdge: .trailing)
            scrollView.autoPinEdge(.bottom, to: .top, of: nextButton)

            stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 18, y: 0))

            stackView.addArrangedSubviews {
                mainView
                showDetailsButton
                detailsView
            }

            nextButton.autoPinEdge(toSuperviewEdge: .leading, withInset: 18)
            nextButton.autoPinEdge(toSuperviewEdge: .trailing, withInset: 18)
            nextButton.autoPinBottomToSuperViewSafeAreaAvoidKeyboard()
        }

        private func addSubviews() {
            addSubview(navigationBar)
            addSubview(scrollView)
            addSubview(nextButton)

            scrollView.contentView.addSubview(stackView)
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

            viewModel.isShowingDetailsDriver
                .drive(onNext: { [weak self] isShowing in
                    self?.detailsView.isHidden = !isShowing
                })
                .disposed(by: disposeBag)

            showDetailsButton.rx.tap
                .bind(to: viewModel.showHideDetailsButtonTapSubject)
                .disposed(by: disposeBag)

            viewModel.errorDriver.map {$0 == nil}
                .drive(nextButton.rx.isEnabled)
                .disposed(by: disposeBag)
        }

        @objc
        private func buttonNextDidTouch() {
            viewModel.authenticateAndSwap()
        }
    }
}
