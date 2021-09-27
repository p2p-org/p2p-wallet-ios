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
        // MARK: - Dependencies
        @Injected private var analyticsManager: AnalyticsManagerType
        
        // MARK: - Properties
        let viewModel: SendTokenViewModelType
        let disposeBag = DisposeBag()
        
        // MARK: - Subviews
        lazy var balanceLabel = UILabel(text: "0", weight: .medium)
            .onTap(self, action: #selector(useAllBalance))
        lazy var coinImageView = CoinLogoImageView(size: 44)
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
            .onTap(self, action: #selector(clearDestinationAddress))
        lazy var qrCodeImageView = UIImageView(width: 35, height: 35, image: .scanQr3, tintColor: .a3a5ba)
            .onTap(self, action: #selector(scanQrCode))
        lazy var errorLabel = UILabel(text: " ", textSize: 12, weight: .medium, textColor: .red, numberOfLines: 0, textAlignment: .center)
        
        lazy var feeLabel = LazyLabel<Double>(textColor: .textSecondary)
        
        lazy var feeInfoButton = UIImageView(width: 16.67, height: 16.67, image: .infoCircle, tintColor: .a3a5ba)
            .onTap(self, action: #selector(showFeeInfo))
        
        lazy var checkingAddressValidityView = UIStackView(axis: .horizontal, spacing: 0, alignment: .fill, distribution: .fill) {
            checkingAddressValidityIndicatorView
            
            UILabel(text: L10n.checkingAddressValidity, textSize: 13, weight: .medium, textColor: .textSecondary, numberOfLines: 0)
                .padding(.init(x: 20, y: 0))
        }
        
        lazy var checkingAddressValidityIndicatorView = UIActivityIndicatorView()
        
        lazy var noFundAddressView = UIStackView(axis: .vertical, spacing: 12, alignment: .fill, distribution: .fill) {
            noFundAddressViewLabel
                .padding(.init(x: 20, y: 0))
            
            UIView.defaultSeparator()
            
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
            .onTap(self, action: #selector(authenticateAndSend))
        
        // MARK: - Initializers
        init(viewModel: SendTokenViewModelType) {
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
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) { [weak self] in
                self?.amountTextField.becomeFirstResponder()
            }
        }
        
        // MARK: - Layout
        private func layout() {
            stackView.addArrangedSubviews {
                UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .equalSpacing) {
                    UILabel(text: L10n.from, weight: .bold)
                    balanceLabel
                }
                BEStackViewSpacing(30)
                
                UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill) {
                    UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill) {
                        coinImageView
                        UIImageView(width: 11, height: 8, image: .downArrow, tintColor: .textBlack)
                    }
                        .onTap(self, action: #selector(chooseWallet))
                    
                    amountTextField
                    
                    changeModeButton
                        .withContentHuggingPriority(.required, for: .horizontal)
                        .padding(.init(all: 10), backgroundColor: .grayPanel, cornerRadius: 12)
                        .onTap(self, action: #selector(switchCurrencyMode))
                }
                BEStackViewSpacing(6)
                
                UIStackView(axis: .horizontal, spacing: 0, alignment: .center, distribution: .fill, arrangedSubviews: [
                    UIView(),
                    equityValueLabel
                ])
                BEStackViewSpacing(20)
                
                UIView.defaultSeparator()
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
                
                UIView.defaultSeparator()
                BEStackViewSpacing(20)
                
                UILabel(text: L10n.sendTo, weight: .bold)
                addressStackView
                    .padding(.init(all: 8), backgroundColor: .a3a5ba.onDarkMode(.h8d8d8d).withAlphaComponent(0.1), cornerRadius: 12)
                
                BEStackViewSpacing(10)
                
                errorLabel
                
                checkingAddressValidityView
                noFundAddressView
                
                BEStackViewSpacing(30)
                
                UIView.defaultSeparator()
                
                BEStackViewSpacing(20)
                
                sendButton
                
                BEStackViewSpacing(16)
                
                UILabel(text: L10n.sendSOLOrAnySPLTokensOnOneAddress, textSize: 14, textColor: .textSecondary, numberOfLines: 0, textAlignment: .center)
                    .padding(.init(x: 20, y: 0))
                
                BEStackViewSpacing(16)
                
                UIView.defaultSeparator()
                
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
            // current wallet
            viewModel.currentWalletDriver
                .drive(onNext: {[weak self] wallet in
                    self?.coinImageView.setUp(wallet: wallet)
                    self?.symbolLabel.text = wallet?.token.symbol
                })
                .disposed(by: disposeBag)
            
            // equity label
            viewModel.currentWalletDriver
                .map {$0?.priceInCurrentFiat == nil}
                .map {$0 ? 0: 1}
                .asDriver(onErrorJustReturn: 1)
                .drive(equityValueLabel.rx.alpha)
                .disposed(by: disposeBag)
            
            Driver.combineLatest(
                Observable.merge(
                    amountTextField.rx.text.map {$0?.double}.asObservable(),
                    viewModel.useAllBalanceSignal.asObservable()
                ).asDriver(onErrorJustReturn: nil),
                viewModel.currentWalletDriver,
                viewModel.currentCurrencyModeDriver
            )
                .map { (amount, wallet, currencyMode) -> String in
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
                .asDriver(onErrorJustReturn: nil)
                .drive(equityValueLabel.rx.text)
                .disposed(by: disposeBag)
            
            // change currency mode button
            viewModel.currentCurrencyModeDriver
                .withLatestFrom(viewModel.currentWalletDriver, resultSelector: {($0, $1)})
                .map {(currencyMode, wallet) -> String? in
                    if currencyMode == .fiat {
                        return Defaults.fiat.code
                    } else {
                        return wallet?.token.symbol
                    }
                }
                .drive(changeModeButton.rx.text)
                .disposed(by: disposeBag)
            
            // amount
            amountTextField.rx.text
                .map {$0?.double}
                .distinctUntilChanged()
                .subscribe(onNext: {[weak self] amount in
                    self?.viewModel.enterAmount(amount)
                })
                .disposed(by: disposeBag)
            
            amountTextField.rx.controlEvent([.editingDidEnd])
                .asObservable()
                .withLatestFrom(amountTextField.rx.text)
                .subscribe(onNext: {[weak self] amount in
                    guard let amount = amount?.double else {return}
                    self?.analyticsManager.log(event: .sendAmountKeydown(sum: amount))
                })
                .disposed(by: disposeBag)
            
            // available amount
            viewModel.availableAmountDriver
                .withLatestFrom(
                    Driver.combineLatest(
                        viewModel.currentWalletDriver,
                        viewModel.currentCurrencyModeDriver
                    ),
                    resultSelector: {($0, $1.0, $1.1)}
                )
                .map { (amount, wallet, mode) -> String? in
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
            
            viewModel.errorDriver
                .map {($0 == L10n.insufficientFunds || $0 == L10n.yourAccountDoesNotHaveEnoughSOLToCoverFee || $0 == L10n.amountIsNotValid) ? UIColor.red: UIColor.h5887ff}
                .drive(balanceLabel.rx.textColor)
                .disposed(by: disposeBag)
            
            // use all balance
            viewModel.useAllBalanceSignal
                .map {$0?.toString(maximumFractionDigits: 9, groupingSeparator: "")}
                .emit(onNext: {[weak self] amount in
                    self?.amountTextField.text = amount
                })
                .disposed(by: disposeBag)
            
            // address
            addressTextField.rx.text
                .skip(while: {$0?.isEmpty == true})
                .subscribe(onNext: {[weak self] address in
                    self?.viewModel.enterWalletAddress(address)
                })
                .disposed(by: disposeBag)
            
            addressTextField.rx.controlEvent([.editingDidEnd])
                .asObservable()
                .subscribe(onNext: { [weak self] _ in
                    self?.analyticsManager.log(event: .sendAddressKeydown)
                })
                .disposed(by: disposeBag)
            
            // ignore no fund address
            ignoreNoFundAddressSwitch.rx.isOn
                .skip(while: {!$0})
                .subscribe(onNext: {[weak self] isIgnored in
                    self?.viewModel.ignoreEmptyBalance(isIgnored)
                })
                .disposed(by: disposeBag)
            
            // price labels
            viewModel.currentWalletDriver
                .map {$0?.token.symbol != nil ? "1 \($0!.token.symbol):": nil}
                .drive(coinSymbolPriceLabel.rx.text)
                .disposed(by: disposeBag)
            
            viewModel.currentWalletDriver
                .map {$0?.priceInCurrentFiat ?? 0}
                .map {"\($0.toString(maximumFractionDigits: 9)) \(Defaults.fiat.symbol)"}
                .drive(coinPriceLabel.rx.text)
                .disposed(by: disposeBag)
            
            // fee
//            feeLabel.subscribed(to: viewModel.output.fee) {
//                "\($0.toString(maximumFractionDigits: 9)) SOL"
//            }
//                .disposed(by: disposeBag)
            
            // receiver address
            viewModel.receiverAddressDriver
                .drive(addressTextField.rx.text)
                .disposed(by: disposeBag)
            
            viewModel.receiverAddressDriver
                .map {!NSRegularExpression.publicKey.matches($0 ?? "")}
                .drive(walletIconView.rx.isHidden)
                .disposed(by: disposeBag)
            
            let destinationAddressInputEmpty = viewModel.receiverAddressDriver
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
            viewModel.errorDriver
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
            viewModel.addressValidationStatusDriver
                .map {$0 == .uncheck || $0 == .valid || $0 == .fetching}
                .drive(noFundAddressView.rx.isHidden)
                .disposed(by: disposeBag)
            
            viewModel.addressValidationStatusDriver
                .map {$0 != .fetching}
                .drive(checkingAddressValidityView.rx.isHidden)
                .disposed(by: disposeBag)
            
            viewModel.addressValidationStatusDriver
                .map {
                    if $0 == .fetchingError {
                        return L10n.ErrorCheckingAddressValidity.areYouSureItSCorrect
                    }
                    return L10n.ThisAddressHasNoFunds.areYouSureItSCorrect
                }
                .drive(noFundAddressViewLabel.rx.text)
                .disposed(by: disposeBag)
            
            viewModel.addressValidationStatusDriver
                .filter {$0 != .invalidIgnored}
                .map {_ in false}
                .drive(ignoreNoFundAddressSwitch.rx.isOn)
                .disposed(by: disposeBag)
            
            // send button
            viewModel.isValidDriver
                .drive(sendButton.rx.isEnabled)
                .disposed(by: disposeBag)
        }
    }
}

private extension SendToken.RootView {
    @objc func useAllBalance() {
        viewModel.useAllBalance()
    }
    
    @objc func chooseWallet() {
        viewModel.navigate(to: .chooseWallet)
    }
    
    @objc func switchCurrencyMode() {
        viewModel.switchCurrencyMode()
    }
    
    @objc func clearDestinationAddress() {
        viewModel.clearDestinationAddress()
    }
    
    @objc func scanQrCode() {
        analyticsManager.log(event: .sendScanQrClick)
        analyticsManager.log(event: .scanQrOpen(fromPage: "send"))
        viewModel.navigate(to: .scanQrCode)
    }
    
    @objc func showFeeInfo() {
        viewModel.navigate(to: .feeInfo)
    }
    
    @objc func authenticateAndSend() {
        viewModel.authenticateAndSend()
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
