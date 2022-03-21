//
//  SwapToken.WalletView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/08/2021.
//

import Foundation
import RxCocoa
import RxSwift

extension SerumSwapV1 {
    class WalletView: BEView {
        // MARK: - Nested type

        enum WalletType {
            case source, destination
        }

        var wallet: Wallet?
        private let disposeBag = DisposeBag()
        private let viewModel: SwapTokenViewModelType
        private let type: WalletType

        private lazy var balanceView = WLBalanceView(forAutoLayout: ())
        private lazy var iconImageView = CoinLogoImageView(size: 32, cornerRadius: 16)

        private lazy var tokenSymbolLabel = UILabel(text: "TOK", weight: .semibold, textAlignment: .center)

        private lazy var maxButton = UILabel(
            text: L10n.max.uppercased(),
            textSize: 13,
            weight: .semibold,
            textColor: .textSecondary.onDarkMode(.white)
        )
        .withContentHuggingPriority(.required, for: .horizontal)
        .padding(.init(x: 13.5, y: 8), backgroundColor: .f6f6f8.onDarkMode(.h404040), cornerRadius: 12)
        .withContentHuggingPriority(.required, for: .horizontal)
        .onTap(self, action: #selector(useAllBalance))

        private lazy var amountTextField = TokenAmountTextField(
            font: .systemFont(ofSize: 27, weight: .bold),
            textColor: .textBlack,
            textAlignment: .right,
            keyboardType: .decimalPad,
            placeholder: "0\(Locale.current.decimalSeparator ?? ".")0",
            autocorrectionType: .no /* , rightView: useAllBalanceButton, rightViewMode: .always */
        )

        private lazy var equityValueLabel = UILabel(
            text: "≈ 0.00 \(Defaults.fiat.symbol)",
            textSize: 13,
            weight: .medium,
            textColor: .textSecondary.onDarkMode(.white),
            textAlignment: .right
        )

        init(viewModel: SwapTokenViewModelType, type: WalletType) {
            self.viewModel = viewModel
            self.type = type
            super.init(frame: .zero)
            configureForAutoLayout()

            bind()
            amountTextField.delegate = self

            layer.cornerRadius = 12
            layer.masksToBounds = true
            layer.borderWidth = 1
            layer.borderColor = UIColor.separator.cgColor
        }

        override func commonInit() {
            super.commonInit()
            let action: Selector = type == .source ? #selector(chooseSourceWallet) : #selector(chooseDestinationWallet)
            let balanceView = type == .destination ? balanceView : balanceView
                .onTap(self, action: #selector(useAllBalance))
            balanceView.tintColor = type == .source ? .h5887ff : .textSecondary.onDarkMode(.white)

            let downArrow = UIImageView(width: 11, height: 8, image: .downArrow, tintColor: .a3a5ba)

            let stackView = UIStackView(axis: .vertical, spacing: 16, alignment: .fill, distribution: .fill) {
                UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .equalCentering) {
                    UILabel(text: type == .source ? L10n.from : L10n.to, textSize: 15, weight: .semibold)
                    balanceView
                }

                UIStackView(axis: .horizontal, spacing: 8, alignment: .center, distribution: .fill) {
                    iconImageView
                    tokenSymbolLabel
                        .withContentHuggingPriority(.required, for: .horizontal)
                    downArrow

                    BEStackViewSpacing(12)
                    maxButton

                    amountTextField
                }

                BEStackViewSpacing(0)

                equityValueLabel
            }

            if type == .destination {
                maxButton.isHidden = true
            }

            addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges(with: .init(all: 16))

            // for increasing touchable area
            let chooseWalletView = UIView(forAutoLayout: ())
                .onTap(self, action: action)
            addSubview(chooseWalletView)
            chooseWalletView.autoPinEdge(.leading, to: .leading, of: iconImageView)
            chooseWalletView.autoPinEdge(.trailing, to: .trailing, of: downArrow)
            chooseWalletView.autoPinEdge(.top, to: .top, of: iconImageView, withOffset: -10)
            chooseWalletView.autoPinEdge(.bottom, to: .bottom, of: iconImageView, withOffset: 10)
        }

        private func bind() {
            // subjects
            let walletDriver: Driver<Wallet?>
            let textFieldKeydownEvent: (Double) -> AnalyticsEvent
            let equityValueLabelDriver: Driver<String?>
            let balanceTextDriver: Driver<String?>
            let inputSubject: PublishRelay<String?>
            let outputDriver: Driver<Double?>

            switch type {
            case .source:
                walletDriver = viewModel.sourceWalletDriver

                textFieldKeydownEvent = { amount in
                    .swapTokenAAmountKeydown(sum: amount)
                }

                equityValueLabelDriver = Driver.combineLatest(
                    viewModel.inputAmountDriver,
                    viewModel.sourceWalletDriver
                )
                .map { amount, wallet in
                    if let wallet = wallet {
                        let value = amount * wallet.priceInCurrentFiat
                        return "≈ \(value.toString(maximumFractionDigits: 9)) \(Defaults.fiat.symbol)"
                    } else {
                        return L10n.selectCurrency
                    }
                }

                inputSubject = viewModel.inputAmountSubject
                outputDriver = viewModel.inputAmountDriver

                // use all balance
                viewModel.useAllBalanceDidTapSignal
                    .map { $0?.toString(maximumFractionDigits: 9, groupingSeparator: "") }
                    .emit(onNext: { [weak self] in
                        // write text without notifying
                        self?.amountTextField.text = $0
                        self?.viewModel.inputAmountSubject.accept($0)
                    })
                    .disposed(by: disposeBag)

                // available amount
                balanceTextDriver = Driver.combineLatest(
                    viewModel.availableAmountDriver,
                    viewModel.sourceWalletDriver
                )
                .map { amount, wallet -> String? in
                    guard let amount = amount else { return nil }
                    return amount.toString(maximumFractionDigits: 9) + " " + wallet?.token.symbol
                }

                viewModel.errorDriver
                    .map { $0 == L10n.insufficientFunds || $0 == L10n.amountIsNotValid }
                    .map { $0 ? UIColor.alert : UIColor.h5887ff }
                    .drive(balanceView.rx.tintColor)
                    .disposed(by: disposeBag)

                Driver.combineLatest(
                    viewModel.inputAmountDriver,
                    viewModel.sourceWalletDriver
                )
                .map { $0 != nil || $1 == nil }
                .drive(maxButton.rx.isHidden)
                .disposed(by: disposeBag)

            case .destination:
                walletDriver = viewModel.destinationWalletDriver

                textFieldKeydownEvent = { amount in
                    .swapTokenBAmountKeydown(sum: amount)
                }

                equityValueLabelDriver = Driver.combineLatest(
                    viewModel.estimatedAmountDriver,
                    viewModel.destinationWalletDriver
                )
                .map { minReceiveAmount, wallet -> String? in
                    guard let symbol = wallet?.token.symbol,
                          let minReceiveAmount = minReceiveAmount?.toString(maximumFractionDigits: 9)
                    else { return nil }
                    return L10n.receiveAtLeast + ": " + minReceiveAmount + " " + symbol
                }

                inputSubject = viewModel.estimatedAmountSubject
                outputDriver = viewModel.estimatedAmountDriver

                balanceTextDriver = viewModel.destinationWalletDriver
                    .map { wallet -> String? in
                        if let amount = wallet?.amount?.toString(maximumFractionDigits: 9) {
                            return amount + " " + "\(wallet?.token.symbol ?? "")"
                        }
                        return nil
                    }
            }

            // wallet
            walletDriver
                .drive(onNext: { [weak self] wallet in
                    self?.setUp(wallet: wallet)
                })
                .disposed(by: disposeBag)

            // balance text
            balanceTextDriver
                .drive(balanceView.balanceLabel.rx.text)
                .disposed(by: disposeBag)

            balanceTextDriver.map { $0 == nil }
                .drive(balanceView.walletView.rx.isHidden)
                .disposed(by: disposeBag)

            // analytics
            amountTextField.rx.controlEvent([.editingDidEnd])
                .asObservable()
                .subscribe(onNext: { [weak self] _ in
                    guard let amount = self?.amountTextField.text?.double else { return }
                    let event = textFieldKeydownEvent(amount)
                    self?.viewModel.log(event)
                })
                .disposed(by: disposeBag)

            // equity value label
            equityValueLabelDriver
                .drive(equityValueLabel.rx.text)
                .disposed(by: disposeBag)

            // input amount
            amountTextField.rx.text
                .filter { [weak self] _ in self?.amountTextField.isFirstResponder == true }
                .distinctUntilChanged()
                .bind(to: inputSubject)
                .disposed(by: disposeBag)

            outputDriver
                .map { $0?.toString(maximumFractionDigits: 9, groupingSeparator: "") }
                .filter { [weak self] _ in self?.amountTextField.isFirstResponder == false }
                .drive(amountTextField.rx.text)
                .disposed(by: disposeBag)
        }

        private func setUp(wallet: Wallet?) {
            amountTextField.setUp(decimals: wallet?.token.decimals)
            iconImageView.setUp(token: wallet?.token, placeholder: .walletPlaceholder)
            tokenSymbolLabel.text = wallet?.token.symbol ?? L10n.select

            self.wallet = wallet
        }

        // MARK: - Actions

        @objc private func chooseSourceWallet() {
            viewModel.navigate(to: .chooseSourceWallet)
        }

        @objc private func chooseDestinationWallet() {
            viewModel.navigate(to: .chooseDestinationWallet)
        }

        @objc private func useAllBalance() {
            viewModel.useAllBalance()
        }
    }
}

// MARK: - TextField delegate

extension SerumSwapV1.WalletView: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool
    {
        if let textField = textField as? TokenAmountTextField {
            return textField.shouldChangeCharactersInRange(range, replacementString: string)
        }
        return true
    }
}
