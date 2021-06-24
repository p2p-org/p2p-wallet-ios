//
//  SendRootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 01/06/2021.
//

import UIKit
import RxSwift
import RxCocoa

extension SendToken {
    class RootView: ScrollableVStackRootView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        let viewModel: ViewModel
        
        // MARK: - Subviews
        lazy var balanceLabel = UILabel(text: "0", weight: .medium)
            .onTap(viewModel, action: #selector(ViewModel.useAllBalance))
        lazy var coinImageView = CoinLogoImageView(size: 44)
            .onTap(viewModel, action: #selector(ViewModel.chooseWallet))
        lazy var amountTextField = TokenAmountTextField(
            font: .systemFont(ofSize: 27, weight: .semibold),
            textColor: .textBlack,
            keyboardType: .decimalPad,
            placeholder: "0\(Locale.current.decimalSeparator ?? ".")0",
            autocorrectionType: .no
        )
        lazy var changeModeButton = UILabel(weight: .semibold, textColor: .a3a5ba)
        lazy var symbolLabel = UILabel(weight: .semibold)
        lazy var equityValueLabel = UILabel(text: "≈", textColor: .textSecondary)
        lazy var coinSymbolPriceLabel = UILabel(textColor: .textSecondary)
        lazy var coinPriceLabel = UILabel(textColor: .textSecondary)
        
        lazy var addressStackView = UIStackView(axis: .horizontal, spacing: 0, alignment: .center, distribution: .fill, arrangedSubviews: [
            walletIconView, addressTextField, clearAddressButton, qrCodeImageView
        ])
        lazy var walletIconView = UIImageView(width: 24, height: 24, image: .walletIcon, tintColor: .a3a5ba)
            .padding(.init(all: 10), backgroundColor: .white.onDarkMode(.h404040), cornerRadius: 12)
        lazy var addressTextField: UITextField = {
            let textField = UITextField(height: 44, backgroundColor: .clear, placeholder: L10n.walletAddress, autocorrectionType: .none, autocapitalizationType: UITextAutocapitalizationType.none, spellCheckingType: .no, horizontalPadding: 8)
            textField.attributedPlaceholder = NSAttributedString(string: L10n.walletAddress, attributes: [.foregroundColor: UIColor.a3a5ba.onDarkMode(.h5887ff)])
            return textField
        }()
        lazy var clearAddressButton = UIImageView(width: 24, height: 24, image: .closeFill, tintColor: UIColor.black.withAlphaComponent(0.6))
            .onTap(viewModel, action: #selector(ViewModel.clearDestinationAddress))
        lazy var qrCodeImageView = UIImageView(width: 35, height: 35, image: .scanQr3, tintColor: .a3a5ba)
            .onTap(viewModel, action: #selector(ViewModel.scanQrCode))
        lazy var errorLabel = UILabel(text: " ", textSize: 12, weight: .medium, textColor: .red, numberOfLines: 0, textAlignment: .center)
        
        lazy var feeLabel = LazyLabel<Double>(textColor: .textSecondary)
        
        lazy var feeInfoButton = UIImageView(width: 16.67, height: 16.67, image: .infoCircle, tintColor: .a3a5ba)
            .onTap(viewModel, action: #selector(ViewModel.showFeeInfo))
        
        lazy var checkingAddressValidityView = UIStackView(axis: .horizontal, spacing: 0, alignment: .fill, distribution: .fill) {
            checkingAddressValidityIndicatorView
            
            UILabel(text: L10n.checkingAddressValidity, textSize: 13, weight: .medium, textColor: .textSecondary, numberOfLines: 0)
                .padding(.init(x: 20, y: 0))
        }
        
        lazy var checkingAddressValidityIndicatorView = UIActivityIndicatorView()
        
        lazy var noFundAddressView = UIStackView(axis: .vertical, spacing: 12, alignment: .fill, distribution: .fill) {
            noFundAddressViewLabel
                .padding(.init(x: 20, y: 0))
            
            UIView.separator(height: 1, color: .separator)
            
            UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill) {
                UILabel(text: L10n.imSureItSCorrect, textSize: 15, weight: .semibold)
                ignoreNoFundAddressSwitch
            }
                .padding(.init(x: 20, y: 0))
            
        }
            .padding(.init(x: 0, y: 12), backgroundColor: .fbfbfd, cornerRadius: 12)
        
        lazy var noFundAddressViewLabel = UILabel(text: L10n.ThisAddressHasNoFunds.areYouSureItSCorrect, textSize: 13, weight: .medium, textColor: .textSecondary, numberOfLines: 0)
        
        lazy var ignoreNoFundAddressSwitch = UISwitch()
        
        lazy var sendButton = WLButton.stepButton(type: .blue, label: L10n.sendNow)
            .onTap(viewModel, action: #selector(ViewModel.authenticateAndSend))
        
        // MARK: - Initializers
        init(viewModel: ViewModel) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }
        
        // MARK: - Methods
        override func commonInit() {
            super.commonInit()
            layout()
            bind()
            amountTextField.delegate = self
        }
        
        override func didMoveToWindow() {
            super.didMoveToWindow()
            amountTextField.becomeFirstResponder()
        }
        
        // MARK: - Layout
        private func layout() {
            stackView.addArrangedSubviews {
                UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .equalSpacing, arrangedSubviews: [
                    UILabel(text: L10n.from, weight: .bold),
                    balanceLabel
                ])
                BEStackViewSpacing(30)
                
                UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill, arrangedSubviews: [
                    coinImageView,
                    UIImageView(width: 11, height: 8, image: .downArrow, tintColor: .textBlack)
                        .onTap(viewModel, action: #selector(ViewModel.chooseWallet)),
                    amountTextField,
                    changeModeButton
                        .withContentHuggingPriority(.required, for: .horizontal)
                        .padding(.init(all: 10), backgroundColor: .grayPanel, cornerRadius: 12)
                        .onTap(viewModel, action: #selector(ViewModel.switchCurrencyMode))
                ])
                BEStackViewSpacing(6)
                
                UIStackView(axis: .horizontal, spacing: 0, alignment: .center, distribution: .fill, arrangedSubviews: [
                    UIView(),
                    equityValueLabel
                ])
                BEStackViewSpacing(20)
                
                UIView.separator(height: 1, color: .separator)
                BEStackViewSpacing(20)
                
                UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill) {
                    UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .equalSpacing) {
                        coinSymbolPriceLabel
                        coinPriceLabel
                    }
                    
                    UIStackView(axis: .horizontal, spacing: 6.67, alignment: .center, distribution: .fill) {
                        UILabel(text: L10n.fee + ":", textColor: .textSecondary)
                        feeLabel
                            .withContentHuggingPriority(.required, for: .horizontal)
                        feeInfoButton
                            .withContentHuggingPriority(.required, for: .horizontal)
                    }
                }
                
                BEStackViewSpacing(20)
                
                UIView.separator(height: 1, color: .separator)
                BEStackViewSpacing(20)
                
                UILabel(text: L10n.sendTo, weight: .bold)
                addressStackView
                    .padding(.init(all: 8), backgroundColor: .a3a5ba.onDarkMode(.h8d8d8d).withAlphaComponent(0.1), cornerRadius: 12)
                
                BEStackViewSpacing(10)
                
                errorLabel
                
                checkingAddressValidityView
                noFundAddressView
                
                BEStackViewSpacing(30)
                
                UIView.separator(height: 1, color: .separator)
                
                BEStackViewSpacing(20)
                
                sendButton
                
                BEStackViewSpacing(16)
                
                UILabel(text: L10n.sendSOLOrAnySPLTokensOnOneAddress, textSize: 14, textColor: .textSecondary, numberOfLines: 0, textAlignment: .center)
                    .padding(.init(x: 20, y: 0))
                
                BEStackViewSpacing(16)
                
                UIView.separator(height: 1, color: .separator)
                
                BEStackViewSpacing(10)
                
                UIView.allDepositsAreStored100NonCustodiallityWithKeysHeldOnThisDevice()
            }
            
            equityValueLabel.autoPinEdge(.leading, to: .leading, of: amountTextField)
            
            scrollView.contentView.addSubview(symbolLabel)
            symbolLabel.centerXAnchor.constraint(equalTo: coinImageView.centerXAnchor).isActive = true
            symbolLabel.centerYAnchor.constraint(equalTo: equityValueLabel.centerYAnchor).isActive = true
            
            feeInfoButton.isHidden = !Defaults.useFreeTransaction
            
            checkingAddressValidityIndicatorView.startAnimating()
        }
        
        private func bind() {
            // bind control to viewModel's input
            amountTextField.rx.text
                .map {$0?.double}
                .distinctUntilChanged()
                .bind(to: viewModel.input.amount)
                .disposed(by: disposeBag)
            
            amountTextField.rx.controlEvent([.editingDidEnd])
                .asObservable()
                .subscribe(onNext: { [weak self] _ in
                    guard let amount = self?.amountTextField.text?.double else {return}
                    self?.viewModel.analyticsManager.log(event: .sendAmountKeydown(sum: amount))
                })
                .disposed(by: disposeBag)
            
            addressTextField.rx.text
                .skip(while: {$0?.isEmpty == true})
                .bind(to: viewModel.input.address)
                .disposed(by: disposeBag)
            
            addressTextField.rx.controlEvent([.editingDidEnd])
                .asObservable()
                .subscribe(onNext: { [weak self] _ in
                    self?.viewModel.analyticsManager.log(event: .sendAddressKeydown)
                })
                .disposed(by: disposeBag)
            
            ignoreNoFundAddressSwitch.rx.isOn
                .skip(while: {!$0})
                .bind(to: viewModel.input.noFundsConfirmation)
                .disposed(by: disposeBag)
            
            // bind viewModel's output
            
            // use all balance did touch
            viewModel.output.useAllBalanceDidTouch
                .map {$0?.toString(maximumFractionDigits: 9, groupingSeparator: "")}
                .drive(amountTextField.rx.text)
                .disposed(by: disposeBag)
            
            // available amount
            Driver.combineLatest(
                viewModel.output.currentWallet,
                viewModel.output.availableAmount,
                viewModel.output.currencyMode
            )
            .map { (wallet, amount, mode) -> String? in
                guard let wallet = wallet, let amount = amount else {return nil}
                var string = L10n.available + ": "
                string += amount.toString(maximumFractionDigits: 9)
                string += " "
                if mode == .fiat {
                    string += Defaults.fiat.code
                } else {
                    string += wallet.token.symbol
                }
                return string
            }
            .drive(balanceLabel.rx.text)
            .disposed(by: disposeBag)
            
            // available amount's color
            viewModel.output.error
                .map {($0 == L10n.insufficientFunds || $0 == L10n.yourAccountDoesNotHaveEnoughSOLToCoverFee || $0 == L10n.amountIsNotValid) ? UIColor.red: UIColor.h5887ff}
                .drive(balanceLabel.rx.textColor)
                .disposed(by: disposeBag)
            
            // current wallet
            viewModel.output.currentWallet
                .drive(onNext: {[weak self] wallet in
                    self?.coinImageView.setUp(wallet: wallet)
                    self?.symbolLabel.text = wallet?.token.symbol
                })
                .disposed(by: disposeBag)
            
            // equity label
            viewModel.output.currentWallet
                .map {$0?.priceInCurrentFiat == nil}
                .map {$0 ? 0: 1}
                .asDriver(onErrorJustReturn: 1)
                .drive(equityValueLabel.rx.alpha)
                .disposed(by: disposeBag)
            
            Driver.combineLatest(
                viewModel.output.currentWallet,
                viewModel.output.currencyMode,
                viewModel.input.amount.asDriver(onErrorJustReturn: nil)
            )
                .map { (wallet, currencyMode, amount) -> String in
                    guard let wallet = wallet else {return ""}
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
                    return "≈ " + equityValue.toString(maximumFractionDigits: 9) + " " + equityValueSymbol
                }
                .drive(equityValueLabel.rx.text)
                .disposed(by: disposeBag)
            
            // change currency mode button
            Driver.combineLatest(
                viewModel.output.currentWallet,
                viewModel.output.currencyMode
            )
                .map {(wallet, currencyMode) -> String? in
                    if currencyMode == .fiat {
                        return Defaults.fiat.code
                    } else {
                        return wallet?.token.symbol
                    }
                }
                .drive(changeModeButton.rx.text)
                .disposed(by: disposeBag)
            
            // price labels
            viewModel.output.currentWallet
                .map {$0?.token.symbol != nil ? "1 \($0!.token.symbol):": nil}
                .drive(coinSymbolPriceLabel.rx.text)
                .disposed(by: disposeBag)
            
            viewModel.output.currentWallet
                .map {$0?.priceInCurrentFiat ?? 0}
                .map {"\($0.toString(maximumFractionDigits: 9)) \(Defaults.fiat.symbol)"}
                .drive(coinPriceLabel.rx.text)
                .disposed(by: disposeBag)
            
            // fee
            feeLabel.subscribed(to: viewModel.output.fee) {
                "\($0.toString(maximumFractionDigits: 9)) SOL"
            }
                .disposed(by: disposeBag)
            
            // receiver address
            viewModel.output.receiverAddress
                .drive(addressTextField.rx.text)
                .disposed(by: disposeBag)
            
            viewModel.output.receiverAddress
                .map {!NSRegularExpression.publicKey.matches($0 ?? "")}
                .drive(walletIconView.rx.isHidden)
                .disposed(by: disposeBag)
            
            let destinationAddressInputEmpty = viewModel.output.receiverAddress
                .map {$0 == nil || $0!.isEmpty}
            
            destinationAddressInputEmpty
                .drive(clearAddressButton.rx.isHidden)
                .disposed(by: disposeBag)
            
            let destinationAddressInputNotEmpty = destinationAddressInputEmpty
                .map {!$0}
            
            destinationAddressInputNotEmpty
                .drive(qrCodeImageView.rx.isHidden)
                .disposed(by: disposeBag)
            
            // error
            viewModel.output.error
                .map {
                    if $0 == L10n.insufficientFunds || $0 == L10n.amountIsNotValid
                    {
                        return nil
                    }
                    return $0
                }
                .asDriver(onErrorJustReturn: nil)
                .drive(errorLabel.rx.text)
                .disposed(by: disposeBag)
            
            // no fund
            viewModel.output.addressValidationStatus
                .map {$0 == .uncheck || $0 == .valid || $0 == .fetching}
                .drive(noFundAddressView.rx.isHidden)
                .disposed(by: disposeBag)
            
            viewModel.output.addressValidationStatus
                .map {$0 != .fetching}
                .drive(checkingAddressValidityView.rx.isHidden)
                .disposed(by: disposeBag)
            
            viewModel.output.addressValidationStatus
                .map {
                    if $0 == .fetchingError {
                        return L10n.ErrorCheckingAddressValidity.areYouSureItSCorrect
                    }
                    return L10n.ThisAddressHasNoFunds.areYouSureItSCorrect
                }
                .drive(noFundAddressViewLabel.rx.text)
                .disposed(by: disposeBag)
            
            viewModel.output.addressValidationStatus
                .filter {$0 != .invalidIgnored}
                .map {_ in false}
                .drive(ignoreNoFundAddressSwitch.rx.isOn)
                .disposed(by: disposeBag)
            
            // send button
            viewModel.output.isValid
                .drive(sendButton.rx.isEnabled)
                .disposed(by: disposeBag)
        }
    }
}

extension SendToken.RootView: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let textField = textField as? TokenAmountTextField {
            return textField.shouldChangeCharactersInRange(range, replacementString: string)
        }
        return true
    }
}
