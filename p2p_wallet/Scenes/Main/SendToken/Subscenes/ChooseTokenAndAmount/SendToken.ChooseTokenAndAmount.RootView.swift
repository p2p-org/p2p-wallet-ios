//
//  SendToken.ChooseTokenAndAmount.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import AnalyticsManager
import Resolver
import RxCocoa
import RxSwift
import UIKit
import KeyAppUI

extension SendToken.ChooseTokenAndAmount {
    class RootView: BEView {
        // MARK: - Constants

        let disposeBag = DisposeBag()

        // MARK: - Properties

        @Injected private var analyticsManager: AnalyticsManager
        private let viewModel: SendTokenChooseTokenAndAmountViewModelType

        private var maxWasClicked = false

        // MARK: - Subviews

        private let walletImageView = UIImageView(
            width: 20,
            height: 20,
            image: .tabBarSelectedWallet,
            tintColor: .textSecondary
        )
        private let balanceLabel = UILabel(text: "0.0", textSize: 15, weight: .medium, textColor: .textSecondary)
        private let coinLogoImageView = CoinLogoImageView(size: 44, cornerRadius: 12)
        private let coinSymbolLabel = UILabel(text: "SOL", textSize: 20, weight: .semibold)
        lazy var amountTextField: TokenAmountTextField = {
            let tf = TokenAmountTextField(
                font: .systemFont(ofSize: 27, weight: .semibold),
                textColor: .textBlack,
                textAlignment: .right,
                keyboardType: .decimalPad,
                placeholder: "0",
                autocorrectionType: .no
            )
            tf.delegate = self
            return tf
        }()

        private lazy var equityValueLabel = UILabel(text: "\(Defaults.fiat.symbol) 0", textSize: 13)
        private lazy var actionButton = TextButton(
            title: viewModel.showAfterConfirmation ? L10n.reviewAndConfirm : L10n.chooseDestinationWallet,
            style: .primary,
            size: .large,
            leading: viewModel.showAfterConfirmation ? .buttonCheckSmall : nil
        ).onTap { [weak self] in
            self?.actionButtonDidTouch()
        }

        #if DEBUG
            private lazy var errorLabel = UILabel(textColor: .alert, numberOfLines: 0, textAlignment: .center)
        #endif

        // MARK: - Initializer

        init(viewModel: SendTokenChooseTokenAndAmountViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }

        // MARK: - Methods

        override func commonInit() {
            super.commonInit()
            layout()
            bind()

            if let initalAmount = viewModel.initialAmount {
                amountTextField.text = initalAmount.toString(maximumFractionDigits: 9, groupingSeparator: "")
                amountTextField.sendActions(for: .valueChanged)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) { [weak self] in
                #if DEBUG
                    if self?.viewModel.showAfterConfirmation == false {
                        self?.amountTextField.text = 0.0001.toString(maximumFractionDigits: 9, groupingSeparator: "")
                        self?.amountTextField.sendActions(for: .valueChanged)
                    }
                #endif
            }
        }

        // MARK: - Layout

        private func layout() {
            let stackView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill) {
                UIView.floatingPanel {
                    UIStackView(axis: .horizontal, spacing: 4, alignment: .center, distribution: .fill) {
                        UILabel(text: L10n.from, textSize: 15, weight: .medium)
                        UIView.spacer
                        walletImageView
                            .onTap(self, action: #selector(useAllBalance))
                        balanceLabel
                            .onTap(self, action: #selector(useAllBalance))
                        UILabel(text: L10n.max.uppercased(), textSize: 15, weight: .medium, textColor: Asset.Colors.night.color)
                            .onTap(self, action: #selector(useAllBalance))
                    }
                    UIStackView(axis: .horizontal, spacing: 8, alignment: .center, distribution: .fill) {
                        UIStackView(axis: .horizontal, spacing: 8, alignment: .center, distribution: .fill) {
                            coinLogoImageView
                                .withContentHuggingPriority(.required, for: .horizontal)
                            coinSymbolLabel
                                .withContentHuggingPriority(.required, for: .horizontal)
                            UIImageView(width: 11, height: 8, image: .downArrow, tintColor: .a3a5ba)
                                .withContentHuggingPriority(.required, for: .horizontal)
                        }
                        .onTap(self, action: #selector(chooseWallet))
                        amountTextField
                    }
                    UIStackView(axis: .horizontal, spacing: 8, alignment: .fill, distribution: .fill) {
                        UIView.spacer
                        UIStackView(axis: .horizontal, spacing: 4, alignment: .center, distribution: .fill) {
                            equityValueLabel
                            UIImageView(width: 20, height: 20, image: .arrowUpDown.withTintColor(Asset.Colors.night.color))
                        }
                        .padding(.init(x: 18, y: 8), cornerRadius: 12)
                        .border(width: 1, color: Asset.Colors.night.color)
                        .onTap(self, action: #selector(toggleCurrencyMode))
                    }
                }
                UIView.spacer
                actionButton
            }
            addSubview(stackView)
            stackView.autoPinEdgesToSuperviewSafeArea(
                with: .init(top: 8, left: 18, bottom: 18, right: 18),
                excludingEdge: .bottom
            )
            stackView.autoPinBottomToSuperViewSafeAreaAvoidKeyboard(inset: 18)

            #if DEBUG
                stackView.addArrangedSubview(errorLabel)
            #endif
        }

        private func bind() {
            viewModel.walletDriver
                .drive(onNext: { [weak self] wallet in
                    self?.coinLogoImageView.setUp(wallet: wallet)
                    self?.coinSymbolLabel.text = wallet?.token.symbol
                    self?.amountTextField.setUp(decimals: wallet?.token.decimals)
                })
                .disposed(by: disposeBag)

            // equity label
            viewModel.walletDriver
                .map { $0?.priceInCurrentFiat == nil }
                .drive(equityValueLabel.rx.isHidden)
                .disposed(by: disposeBag)

            Driver.combineLatest(
                viewModel.amountDriver,
                viewModel.walletDriver,
                viewModel.currencyModeDriver
            ).map { amount, wallet, currencyMode -> String in
                guard let wallet = wallet else { return "" }

                var equityValue = amount * wallet.priceInCurrentFiat
                var equityValueSymbol = Defaults.fiat.code
                if currencyMode == .fiat {
                    if wallet.priceInCurrentFiat > 0 {
                        equityValue = amount / wallet.priceInCurrentFiat
                    } else {
                        equityValue = 0
                    }
                    equityValueSymbol = wallet.token.symbol
                }
                let value = currencyMode != .fiat
                    ? equityValue.toString(maximumFractionDigits: 2, groupingSeparator: " ")
                    : equityValue.toString(maximumFractionDigits: 9, groupingSeparator: "")
                return equityValueSymbol + " " + value
            }
            .asDriver()
            .drive(equityValueLabel.rx.text)
            .disposed(by: disposeBag)

            // amount
            amountTextField.rx.text
                .subscribe(onNext: { [weak self] text in
                    self?.viewModel.enterAmount(Double(text ?? "") ?? 0)
                })
                .disposed(by: disposeBag)

            amountTextField.rx.controlEvent([.editingDidEnd])
                .asObservable()
                .withLatestFrom(amountTextField.rx.text)
                .subscribe(onNext: { [weak self] amount in
                    guard let amount = amount?.double else { return }
                    self?.analyticsManager.log(event: AmplitudeEvent.sendAmountKeydown(sum: amount))
                })
                .disposed(by: disposeBag)

            viewModel.amountDriver
                .distinctUntilChanged()
                .skip(1) // skipping initial value
                .withLatestFrom(viewModel.walletDriver, resultSelector: { ($0, $1) })
                .map { $0.0?.toString(maximumFractionDigits: Int($0.1?.token.decimals ?? 0), groupingSeparator: "") }
                .drive(amountTextField.rx.text)
                .disposed(by: disposeBag)

            // available amount
            let balanceTextDriver = Driver.combineLatest(
                viewModel.walletDriver,
                viewModel.currencyModeDriver
            )
                .map { [weak self] wallet, mode -> String? in
                    guard
                        let wallet = wallet,
                        let amount = self?.viewModel.calculateAvailableAmount()
                    else { return nil }

                    var string = amount.toString(maximumFractionDigits: mode == .fiat ? 2 : 9) + " "
                    string += mode == .fiat ? Defaults.fiat.code : wallet.token.symbol
                    return string
                }

            balanceTextDriver
                .drive(balanceLabel.rx.text)
                .disposed(by: disposeBag)

            // error
            let balanceTintColorDriver = viewModel.errorDriver
                .withLatestFrom(viewModel.amountDriver.map(\.isNilOrZero)) { ($0, $1) }
                .map { error, amountIsNilOrZero -> UIColor in
                    var color = UIColor.textSecondary
                    if error != nil, !amountIsNilOrZero {
                        color = .alert
                    }
                    return color
                }

            balanceTintColorDriver
                .drive(walletImageView.rx.tintColor)
                .disposed(by: disposeBag)

            balanceTintColorDriver
                .drive(balanceLabel.rx.textColor)
                .disposed(by: disposeBag)

            // action button
            viewModel.errorDriver
                .map { [weak self] in
                    $0?.buttonSuggestion ??
                        (
                            self?.viewModel.showAfterConfirmation == true ?
                                L10n.reviewAndConfirm :
                                L10n.chooseTheRecipient
                        )
                }
                .drive(actionButton.rx.title)
                .disposed(by: disposeBag)

            viewModel.errorDriver
                .map { [weak self] in
                    $0 != nil ? nil : (
                        self?.viewModel.showAfterConfirmation == true ?
                            .buttonCheckSmall :
                            .buttonChooseTheRecipient
                    )
                }
                .drive(actionButton.rx.leadingImage)
                .disposed(by: disposeBag)

            viewModel.errorDriver
                .map { $0 == nil }
                .drive(actionButton.rx.isEnabled)
                .disposed(by: disposeBag)

            #if DEBUG
                viewModel.errorDriver
                    .map { String(describing: $0?.rawValue) }
                    .drive(errorLabel.rx.text)
                    .disposed(by: disposeBag)
            #endif
        }

        // MARK: - Actions

        @objc private func useAllBalance() {
            let availableAmount = viewModel.calculateAvailableAmount()
            let string = availableAmount.toString(maximumFractionDigits: 9, groupingSeparator: "")
            amountTextField.text = string
            amountTextField.sendActions(for: .editingChanged)
            maxWasClicked = true
        }

        @objc private func chooseWallet() {
            viewModel.navigate(to: .chooseWallet)
        }

        @objc private func toggleCurrencyMode() {
            viewModel.toggleCurrencyMode()
        }

        @objc private func actionButtonDidTouch() {
            guard viewModel.isTokenValidForSelectedNetwork() else { return }
            viewModel.save()
            if viewModel.showAfterConfirmation {
                viewModel.navigate(to: .backToConfirmation)
            } else {
                viewModel.navigateNext(maxWasClicked: maxWasClicked)
            }
        }
    }
}

extension SendToken.ChooseTokenAndAmount.RootView: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool
    {
        switch textField {
        case let amountTextField as TokenAmountTextField:
            return amountTextField.shouldChangeCharactersInRange(range, replacementString: string)
        default:
            return true
        }
    }
}
