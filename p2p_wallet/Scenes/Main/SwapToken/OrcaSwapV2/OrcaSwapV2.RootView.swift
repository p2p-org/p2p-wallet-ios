//
//  OrcaSwapV2.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/10/2021.
//

import Combine
import CombineCocoa
import UIKit

extension OrcaSwapV2 {
    final class RootView: ScrollableVStackRootView {
        // MARK: - Constants

        var subscriptions = [AnyCancellable]()

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
            viewModel.loadingStatePublisher
                .sink { [weak self] loadableState in
                    self?.setUp(loadableState, reloadAction: { [weak self] in
                        Task { await self?.viewModel.reload() }
                    })
                }
                .store(in: &subscriptions)

            viewModel.isShowingDetailsPublisher
                .sink { [weak showDetailsButton] in showDetailsButton?.isOpened = $0 }
                .store(in: &subscriptions)

            viewModel.isShowingDetailsPublisher
                .sink { [weak self] isShowing in
                    guard let self = self else { return }
                    self.stackView.setIsHidden(!isShowing, on: self.detailsView, animated: true)
                }
                .store(in: &subscriptions)

            viewModel.isShowingDetailsPublisher
                .sink { [weak self] isShowing in
                    if isShowing {
                        self?.endEditing(true)
                    }
                }
                .store(in: &subscriptions)

            viewModel.isShowingShowDetailsButtonPublisher
                .sink { [weak self] isShowing in
                    self?.showDetailsButton.isHidden = !isShowing
                }
                .store(in: &subscriptions)

            showDetailsButton.tapPublisher
                .sink { [weak self] in
                    self?.viewModel.showHideDetailsButtonTapSubject.send()
                }
                .store(in: &subscriptions)

            viewModel.errorPublisher.map { $0 == nil }
                .assign(to: \.isEnabled, on: nextButton)
                .store(in: &subscriptions)

            Publishers.CombineLatest(
                viewModel.errorPublisher,
                viewModel.feePayingTokenPublisher.map { $0?.token.symbol }
            )
                .sink { [weak self] in
                    self?.setError(error: $0, feePayingTokenSymbol: $1)
                }
                .store(in: &subscriptions)
        }

        private func setError(error: OrcaSwapV2.VerificationError?, feePayingTokenSymbol: String?) {
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
                text = L10n.yourAccountDoesNotHaveEnoughToCoverFees(feePayingTokenSymbol ?? "")
            case .unknown:
                text = L10n.unknownError
            case .none:
                text = L10n.reviewAndConfirm
                image = .buttonCheckSmall
            case .some(.payingFeeWalletNotFound):
                // TODO: fix
                text = "payingFeeWalletNotFound"
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
