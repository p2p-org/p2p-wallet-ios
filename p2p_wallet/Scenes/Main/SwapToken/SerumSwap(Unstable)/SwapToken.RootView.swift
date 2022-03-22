//
//  SwapToken.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/08/2021.
//

import Action
import RxCocoa
import RxSwift
import UIKit

extension SerumSwapV1 {
    class RootView: ScrollableVStackRootView {
        // MARK: - Constants

        private let disposeBag = DisposeBag()

        // MARK: - Properties

        private let viewModel: SwapTokenViewModelType

        // MARK: - Subviews

        private lazy var sourceWalletView = WalletView(viewModel: viewModel, type: .source)
        private lazy var reverseButton = UIImageView(width: 44, height: 44, cornerRadius: 12, image: .reverseButton)
            .onTap(self, action: #selector(swapSourceAndDestination))
        private lazy var destinationWalletView = WalletView(viewModel: viewModel, type: .destination)

        private lazy var exchangeRateLabel = UILabel(textSize: 15, weight: .medium)
        private lazy var exchangeRateReverseButton = UIImageView(
            width: 18,
            height: 18,
            image: .walletSwap,
            tintColor: .h8b94a9
        )
        .padding(.init(all: 3))
        .onTap(self, action: #selector(reverseExchangeRate))

        private lazy var slippageLabel = UILabel(textSize: 15, weight: .medium, numberOfLines: 0)

        private lazy var swapFeeLabel = UILabel(text: L10n.swapFees, textSize: 15, weight: .medium)
        private lazy var errorLabel = UILabel(
            textSize: 15,
            weight: .medium,
            textColor: .alert,
            numberOfLines: 0,
            textAlignment: .center
        )

        private lazy var swapButton = WLButton.stepButton(type: .blue, label: L10n.swapNow)
            .onTap(self, action: #selector(authenticateAndSwap))

        // MARK: - Initializers

        init(viewModel: SwapTokenViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }

        // MARK: - Methods

        override func commonInit() {
            super.commonInit()
            layout()
            bind()
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
        }

        // MARK: - Layout

        private func layout() {
            stackView.spacing = 16
            stackView.addArrangedSubviews {
                sourceWalletView

                swapSourceAndDestinationView()

                destinationWalletView

                UIView.createSectionView(
                    title: L10n.currentPrice,
                    contentView: exchangeRateLabel,
                    rightView: exchangeRateReverseButton,
                    addSeparatorOnTop: false
                )
                .withTag(1)

                UIView.defaultSeparator()
                    .withTag(2)

                UIView.createSectionView(
                    title: L10n.maxPriceSlippage,
                    contentView: slippageLabel,
                    addSeparatorOnTop: false
                )
                .onTap(self, action: #selector(chooseSlippage))
                .withTag(3)

                UIView.defaultSeparator()
                    .withTag(4)

                UIView.createSectionView(
                    label: swapFeeLabel,
                    contentView: UIView(),
                    addSeparatorOnTop: false
                )
                .withModifier { view in
                    let view = view
                    view.autoSetDimension(.height, toSize: 48, relation: .greaterThanOrEqual)
                    return view
                }
                .onTap(self, action: #selector(showSwapFees))
                .withTag(5)

                errorLabel

                swapButton

                BEStackViewSpacing(20)
                UIStackView(axis: .horizontal, spacing: 8, alignment: .center, distribution: .fill) {
                    UILabel(text: L10n.poweredBy, textSize: 13, textColor: .textSecondary, textAlignment: .center)
                    viewModel.providerSignatureView()
                }
                .centeredHorizontallyView
            }
        }

        private func bind() {
            // initial state
            viewModel.initialStateDriver
                .drive(onNext: { [weak self] state in
                    self?.setUp(initialState: state)
                })
                .disposed(by: disposeBag)

            // exchange rate
            viewModel.exchangeRateDriver
                .map { $0.state != .loading && $0.state != .loaded }
                .drive(
                    stackView.viewWithTag(1)!.rx.isHidden,
                    stackView.viewWithTag(2)!.rx.isHidden
                )
                .disposed(by: disposeBag)

            Driver.combineLatest(
                viewModel.exchangeRateDriver,
                viewModel.isExchangeRateReversedDriver
            )
            .withLatestFrom(
                Driver.combineLatest(
                    viewModel.sourceWalletDriver,
                    viewModel.destinationWalletDriver
                ),
                resultSelector: { ($0.0, $0.1, $1.0, $1.1) }
            )
            .map(generateExchangeRateText)
            .drive(exchangeRateLabel.rx.text)
            .disposed(by: disposeBag)

            // slippage
            viewModel.slippageDriver
                .map { NSAttributedString.slippageAttributedText(slippage: $0) }
                .drive(slippageLabel.rx.attributedText)
                .disposed(by: disposeBag)

            // fee
            viewModel.feesDriver.map { $0.state != .loaded }
                .drive(
                    stackView.viewWithTag(4)!.rx.isHidden,
                    stackView.viewWithTag(5)!.rx.isHidden
                )
                .disposed(by: disposeBag)

            // error label
            let presentableErrorDriver = Driver.combineLatest(
                viewModel.inputAmountDriver,
                viewModel.minOrderSizeDriver,
                viewModel.exchangeRateDriver.map(\.state),
                viewModel.feesDriver.map(\.state),
                viewModel.errorDriver
            )
            .map(generateErrorText)

            presentableErrorDriver
                .map { $0 == nil }
                .drive(errorLabel.rx.isHidden)
                .disposed(by: disposeBag)

            presentableErrorDriver
                .drive(errorLabel.rx.text)
                .disposed(by: disposeBag)

            // button
            Driver.combineLatest([
                viewModel.initialStateDriver.map { $0 == .loaded },
                viewModel.exchangeRateDriver.map { $0.state == .loaded },
                viewModel.feesDriver.map { $0.state == .loaded },
                viewModel.errorDriver.map { $0 == nil },
            ])
            .map { $0.allSatisfy { $0 }}
            .drive(swapButton.rx.isEnabled)
            .disposed(by: disposeBag)

            Driver.combineLatest(
                viewModel.exchangeRateDriver,
                viewModel.feesDriver,
                viewModel.sourceWalletDriver.map { $0 == nil },
                viewModel.destinationWalletDriver.map { $0 == nil },
                viewModel.inputAmountDriver.map { $0 == nil },
                viewModel.errorDriver
            )
            .map(generateSwapButtonText)
            .drive(swapButton.rx.title())
            .disposed(by: disposeBag)
        }

        // MARK: - Actions

        @objc private func swapSourceAndDestination() {
            viewModel.swapSourceAndDestination()
        }

        @objc private func reverseExchangeRate() {
            viewModel.reverseExchangeRate()
        }

        @objc private func authenticateAndSwap() {
            viewModel.authenticateAndSwap()
        }

        @objc private func chooseSlippage() {
            viewModel.navigate(to: .chooseSlippage)
        }

        @objc private func showSwapFees() {
            viewModel.navigate(to: .swapFees)
        }

        // MARK: - Helpers

        private func swapSourceAndDestinationView() -> UIView {
            let view = UIView(forAutoLayout: ())
            let separator = UIView.defaultSeparator()
            view.addSubview(separator)
            separator.autoPinEdge(toSuperviewEdge: .leading, withInset: 8)
            separator.autoAlignAxis(toSuperviewAxis: .horizontal)

            view.addSubview(reverseButton)
            reverseButton.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .leading)
            separator.autoPinEdge(.trailing, to: .leading, of: reverseButton, withOffset: -8)

            return view
        }
    }
}

extension SerumSwapV1.RootView {
    private func setUp(initialState: LoadableState) {
        removeErrorView()
        stackView.isHidden = false

        if initialState.isError {
            stackView.isHidden = true
            showErrorView(
                title: L10n.swappingIsCurrentlyUnavailable,
                description: L10n.swappingIsCurrentlyUnavailable,
                retryAction: CocoaAction { [weak self] in
                    self?.viewModel.reload()
                    return .just(())
                }
            )
        }
    }
}

// MARK: - Text generators

private func generateExchangeRateText(
    exrate: Loadable<Double>,
    isReversed: Bool,
    source: Wallet?,
    destination: Wallet?
) -> String? {
    // if exrate is loading
    if exrate.state == .loading {
        return L10n.loading + "..."
    }

    // exrate is loaded or error
    guard let source = source,
          let destination = destination,
          exrate.state == .loaded,
          var rate = exrate.value
    else {
        return nil
    }
    if rate != 0, isReversed {
        rate = 1 / rate
    }
    var string = rate.toString(maximumFractionDigits: 9)
    string += " "
    string += isReversed ? destination.token.symbol : source.token.symbol
    string += " "
    string += L10n.per
    string += " "
    string += isReversed ? source.token.symbol : destination.token.symbol
    return string
}

private func generateSwapButtonText(
    exrate: Loadable<Double?>,
    fees: Loadable<[PayingFee]>,
    isSourceWalletEmpty: Bool,
    isDestinationWalletEmpty: Bool,
    isAmountNil: Bool,
    error: String?
) -> String? {
    if exrate.state == .loading {
        return L10n.loadingExchangeRate + "..."
    }
    if fees.state == .loading {
        return L10n.calculatingFees + "..."
    }
    if isSourceWalletEmpty || isDestinationWalletEmpty {
        return L10n.selectToken
    }
    if isAmountNil {
        return L10n.enterTheAmount
    }
    if error == L10n.slippageIsnTValid {
        return L10n.enterANumberLessThanD(Int(Double.maxSlippage * 100))
    }
    if error == L10n.insufficientFunds {
        return L10n.donTGoOverTheAvailableFunds
    }
    return L10n.swapNow
}

private func generateErrorText(
    amount: Double?,
    minOrderSize: Loadable<Double>,
    exrate: LoadableState,
    fees: LoadableState,
    error: String?
) -> String? {
    // if failed to get exchange rate and fees
    if exrate.isError || fees.isError || minOrderSize.state.isError {
        return L10n.couldNotCalculateExchangeRateOrSwappingFeesFromCurrentTokenPair
    }

    // if amount is too small
    if let amount = amount,
       let minOrderSize = minOrderSize.value,
       amount < minOrderSize
    {
        return L10n.inputAmountIsTooSmallMinimumAmountForSwappingIs(minOrderSize.toString(maximumFractionDigits: 9))
    }

    guard let error = error else { return nil }

    let hiddenErrors = [
        L10n.insufficientFunds,
        L10n.amountIsNotValid,
        L10n.slippageIsnTValid,
        L10n.someParametersAreMissing,
    ] // hide these error (already shown in another place)

    if !hiddenErrors.contains(error) { return error }
    return nil
}
