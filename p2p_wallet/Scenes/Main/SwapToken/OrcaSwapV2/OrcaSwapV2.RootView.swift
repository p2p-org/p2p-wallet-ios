//
//  OrcaSwapV2.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/10/2021.
//

import UIKit
import RxSwift
import RxCocoa

extension OrcaSwapV2 {
    final class RootView: ScrollableVStackRootView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        private let viewModel: OrcaSwapV2ViewModelType

        // MARK: - Subviews
        private lazy var nextButton = WLStepButton.main(image: .buttonCheckSmall, text: L10n.reviewAndConfirm)
            .onTap(self, action: #selector(buttonNextDidTouch))

        private lazy var mainView = OrcaSwapV2.MainSwapView(viewModel: viewModel)
        private let showDetailsButton = ShowHideButton(closedText: L10n.showDetails, openedText: L10n.hideDetails)
        private lazy var detailsView = OrcaSwapV2.DetailsView(viewModel: viewModel)
        
        // MARK: - Initializer
        init(viewModel: OrcaSwapV2ViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }
        
        // MARK: - Methods
        override func commonInit() {
            super.commonInit()
            scrollView.showsVerticalScrollIndicator = false
            layout()
            bind()
        }

        func makeFromFirstResponder() {
            mainView.makeFromFirstResponder()
        }

        // MARK: - Layout
        private func layout() {
            stackView.addArrangedSubviews {
                mainView
                showDetailsButton
                detailsView
            }
            
            addSubview(nextButton)
            nextButton.autoPinEdge(toSuperviewEdge: .leading, withInset: 18)
            nextButton.autoPinEdge(toSuperviewEdge: .trailing, withInset: 18)
            nextButton.autoPinBottomToSuperViewSafeAreaAvoidKeyboard(inset: 18)
            
            scrollViewBottomConstraint.isActive = false
            scrollView.autoPinEdge(.bottom, to: .top, of: nextButton, withOffset: 8)
        }
        
        private func bind() {
            viewModel.loadingStateDriver
                .drive(rx.loadableState {[weak self] in
                    self?.viewModel.reload()
                })
                .disposed(by: disposeBag)

            viewModel.isShowingDetailsDriver
                .drive(showDetailsButton.rx.isOpened)
                .disposed(by: disposeBag)

            viewModel.isShowingDetailsDriver
                .drive { [weak self] isShowing in
                    guard let self = self else {return}
                    self.stackView.setIsHidden(!isShowing, on: self.detailsView, animated: true)
                }
                .disposed(by: disposeBag)

            viewModel.isShowingDetailsDriver
                .drive { [weak self] isShowing in
                    if isShowing {
                        self?.endEditing(true)
                    }
                }
                .disposed(by: disposeBag)

            viewModel.isShowingShowDetailsButtonDriver
                .drive { [weak self] isShowing in
                    self?.showDetailsButton.isHidden = !isShowing
                }
                .disposed(by: disposeBag)

            showDetailsButton.rx.tap
                .bind(to: viewModel.showHideDetailsButtonTapSubject)
                .disposed(by: disposeBag)

            viewModel.errorDriver.map {$0 == nil}
                .drive(nextButton.rx.isEnabled)
                .disposed(by: disposeBag)

            Driver.combineLatest(
                viewModel.errorDriver,
                viewModel.sourceWalletDriver.map { $0?.token.symbol }
            )
                .drive { [weak self] in
                    self?.setError(error: $0, sourceSymbol: $1)
                }
                .disposed(by: disposeBag)
        }

        private func setError(error: OrcaSwapV2.VerificationError?, sourceSymbol: String?) {
            let text: String
            var image: UIImage?

            switch error {
            case .swappingIsNotAvailable:
                text = L10n.swappingIsCurrentlyUnavailable
            case .sourceWalletIsEmpty:
                text = L10n.chooseSourceWallet
            case .destinationWalletIsEmpty:
                text = L10n.chooseDestinationWallet
            case .canNotSwapToItSelf:
                text = L10n.chooseAnotherDestinationWallet
            case .tradablePoolsPairsNotLoaded:
                text = L10n.loading
            case .tradingPairNotSupported:
                text = L10n.thisTradingPairIsNotSupported
            case .feesIsBeingCalculated:
                text = L10n.calculatingFees
            case .couldNotCalculatingFees:
                text = L10n.couldNotCalculatingFees
            case .inputAmountIsEmpty:
                text = L10n.enterTheAmount
            case .inputAmountIsNotValid:
                text = L10n.inputAmountIsNotValid
            case .insufficientFunds:
                text = L10n.insufficientFunds
            case .estimatedAmountIsNotValid:
                text = L10n.amountIsTooSmall
            case .bestPoolsPairsIsEmpty:
                text = L10n.thisTradingPairIsNotSupported
            case .slippageIsNotValid:
                text = L10n.chooseAnotherSlippage
            case .nativeWalletNotFound:
                text = L10n.couldNotConnectToWallet
            case .notEnoughSOLToCoverFees:
                text = L10n.yourAccountDoesNotHaveEnoughSOLToCoverFee
            case .notEnoughBalanceToCoverFees:
                text = L10n.yourAccountDoesNotHaveEnoughToCoverFees(sourceSymbol ?? "")
            case .unknown:
                text = L10n.unknownError
            case .none:
                text = L10n.reviewAndConfirm
                image = .buttonCheckSmall
            case .some(.payingFeeWalletNotFound):
                // TODO: fix
                text =  "payingFeeWalletNotFound"
            }

            nextButton.setTitle(text: text)
            nextButton.setImage(image: image)
        }
        @objc
        private func buttonNextDidTouch() {
            viewModel.navigate(to: .confirmation)
        }
    }
}
