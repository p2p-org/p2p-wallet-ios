//
//  SendToken.ChooseTokenAndAmount.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import UIKit
import RxSwift
import RxCocoa

extension SendToken.ChooseTokenAndAmount {
    class RootView: BEView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        @Injected private var analyticsManager: AnalyticsManagerType
        private let viewModel: SendTokenChooseTokenAndAmountViewModelType
        
        // MARK: - Subviews
        private let walletImageView = UIImageView(width: 20, height: 20, image: .tabbarWallet, tintColor: .textSecondary)
        private let balanceLabel = UILabel(text: "0.0", textSize: 15, weight: .medium, textColor: .textSecondary)
        private let coinLogoImageView = CoinLogoImageView(size: 44, cornerRadius: 12)
        private let coinSymbolLabel = UILabel(text: "SOL", textSize: 20, weight: .semibold)
        private lazy var amountTextField: TokenAmountTextField = {
            let tf = TokenAmountTextField(
                font: .systemFont(ofSize: 27, weight: .semibold),
                textColor: .textBlack,
                textAlignment: .right,
                keyboardType: .decimalPad,
                placeholder: "0\(Locale.current.decimalSeparator ?? ".")0",
                autocorrectionType: .no
            )
            tf.delegate = self
            return tf
        }()
        private lazy var equityValueLabel = UILabel(text: "\(Defaults.fiat.symbol) 0", textSize: 13)
        private lazy var actionButton = WLStepButton.main(text: L10n.chooseDestinationWallet)
            .onTap(self, action: #selector(actionButtonDidTouch))
        
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
        }
        
        override func didMoveToWindow() {
            super.didMoveToWindow()
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) { [weak self] in
                self?.amountTextField.becomeFirstResponder()
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
                        UILabel(text: L10n.max.uppercased(), textSize: 15, weight: .medium, textColor: .h5887ff)
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
                            UIImageView(width: 20, height: 20, image: .arrowUpDown)
                        }
                            .padding(.init(x: 18, y: 8), cornerRadius: 12)
                            .border(width: 1, color: .defaultBorder)
                            .onTap(self, action: #selector(toggleCurrencyMode))
                    }
                }
                UIView.spacer
                actionButton
            }
            addSubview(stackView)
            stackView.autoPinEdgesToSuperviewSafeArea(with: .init(top: 8, left: 18, bottom: 18, right: 18), excludingEdge: .bottom)
            stackView.autoPinBottomToSuperViewSafeAreaAvoidKeyboard()
            
            #if DEBUG
            stackView.addArrangedSubview(errorLabel)
            #endif
        }
        
        private func bind() {
            viewModel.walletDriver
                .drive(onNext: {[weak self] wallet in
                    self?.coinLogoImageView.setUp(wallet: wallet)
                    self?.coinSymbolLabel.text = wallet?.token.symbol
                })
                .disposed(by: disposeBag)
            
            // equity label
            viewModel.walletDriver
                .map {$0?.priceInCurrentFiat == nil}
                .drive(equityValueLabel.rx.isHidden)
                .disposed(by: disposeBag)
            
            Driver.combineLatest(
                viewModel.amountDriver,
                viewModel.walletDriver,
                viewModel.currencyModeDriver
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
                    return equityValueSymbol + " " + equityValue.toString(maximumFractionDigits: 9)
                }
                .asDriver(onErrorJustReturn: nil)
                .drive(equityValueLabel.rx.text)
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
            let balanceTextDriver = Driver.combineLatest(
                viewModel.walletDriver,
                viewModel.currencyModeDriver
            )
                .map {[weak self] (wallet, mode) -> String? in
                    guard let wallet = wallet, let amount = self?.viewModel.calculateAvailableAmount() else {return nil}
                    var string = amount.toString(maximumFractionDigits: 9)
                    string += " "
                    if mode == .fiat {
                        string += Defaults.fiat.code
                    } else {
                        string += wallet.token.symbol
                    }
                    return string
                }
                
            balanceTextDriver
                .drive(balanceLabel.rx.text)
                .disposed(by: disposeBag)
            
            // error
            let balanceTintColorDriver = viewModel.errorDriver
                .skip(1)
                .map {$0 == nil ? UIColor.textSecondary: UIColor.alert}
            
            balanceTintColorDriver
                .drive(walletImageView.rx.tintColor)
                .disposed(by: disposeBag)
            
            balanceTintColorDriver
                .drive(balanceLabel.rx.textColor)
                .disposed(by: disposeBag)
            
            viewModel.errorDriver
                .map {$0?.buttonSuggestion ?? L10n.chooseTheRecipient}
                .drive(actionButton.rx.text)
                .disposed(by: disposeBag)
            
            viewModel.errorDriver
                .map {$0 == nil ? UIImage.buttonChooseTheRecipient: nil}
                .drive(actionButton.rx.image)
                .disposed(by: disposeBag)
            
            viewModel.errorDriver
                .map {$0 == nil}
                .drive(actionButton.rx.isEnabled)
                .disposed(by: disposeBag)
            
            #if DEBUG
            viewModel.errorDriver
                .map {String(describing: $0?.rawValue)}
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
        }
        
        @objc private func chooseWallet() {
            viewModel.navigate(to: .chooseWallet)
        }
        
        @objc private func toggleCurrencyMode() {
            viewModel.toggleCurrencyMode()
        }
        
        @objc private func actionButtonDidTouch() {
            viewModel.next()
        }
    }
}

extension SendToken.ChooseTokenAndAmount.RootView: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        switch textField {
        case let amountTextField as TokenAmountTextField:
            return amountTextField.shouldChangeCharactersInRange(range, replacementString: string)
        default:
            return true
        }
    }
}
