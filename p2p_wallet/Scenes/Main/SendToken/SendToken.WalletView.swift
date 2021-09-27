//
//  SendToken.WalletView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/09/2021.
//

import Foundation
import RxSwift
import RxCocoa

extension SendToken {
    class WalletView: BEView {
        // MARK: - Properties
        @Injected private var analyticsManager: AnalyticsManagerType
        private let disposeBag = DisposeBag()
        let viewModel: SendTokenViewModelType
        
        // MARK: - Subviews
        private lazy var balanceView = WLBalanceView(forAutoLayout: ())
            .onTap(self, action: #selector(useAllBalance))
        lazy var coinImageView = CoinLogoImageView(size: 32, cornerRadius: 16)
        lazy var amountTextField = TokenAmountTextField(
            font: .systemFont(ofSize: 27, weight: .semibold),
            textColor: .textBlack,
            textAlignment: .right,
            keyboardType: .decimalPad,
            placeholder: "0\(Locale.current.decimalSeparator ?? ".")0",
            autocorrectionType: .no
        )
        lazy var changeModeButton = UILabel(textSize: 13, weight: .semibold, textColor: .a3a5ba)
        lazy var symbolLabel = UILabel(weight: .semibold)
        lazy var equityValueLabel = UILabel(text: "≈", textColor: .textSecondary, textAlignment: .right)
        
        // MARK: - Initializer
        init(viewModel: SendTokenViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }
        
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
        
        private func layout() {
            let contentView = UIStackView(axis: .vertical, spacing: 16, alignment: .fill, distribution: .fill) {
                
                UIStackView(axis: .horizontal, spacing: 8, alignment: .center, distribution: .equalSpacing) {
                    UILabel(text: L10n.from, textSize: 15, weight: .semibold)
                    balanceView
                }
                
                UIStackView(axis: .horizontal, spacing: 8, alignment: .center, distribution: .fill) {
                    coinImageView
                        .onTap(self, action: #selector(chooseWallet))
                    symbolLabel
                        .withContentHuggingPriority(.required, for: .horizontal)
                        .onTap(self, action: #selector(chooseWallet))
                    UIImageView(width: 11, height: 8, image: .downArrow, tintColor: .a3a5ba)
                        .onTap(self, action: #selector(chooseWallet))
                    BEStackViewSpacing(12)
                    changeModeButton
                        .withContentHuggingPriority(.required, for: .horizontal)
                        .padding(.init(all: 10), backgroundColor: .grayPanel, cornerRadius: 12)
                        .onTap(self, action: #selector(switchCurrencyMode))
                    amountTextField
                }
                
                BEStackViewSpacing(0)
                
                equityValueLabel
            }
                .padding(.init(all: 16), cornerRadius: 12)
                .border(width: 1, color: .defaultBorder)
            
            addSubview(contentView)
            contentView.autoPinEdgesToSuperviewEdges()
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
            let balanceTextDriver = viewModel.availableAmountDriver
                .withLatestFrom(
                    Driver.combineLatest(
                        viewModel.currentWalletDriver,
                        viewModel.currentCurrencyModeDriver
                    ),
                    resultSelector: {($0, $1.0, $1.1)}
                )
                .map { (amount, wallet, mode) -> String? in
                    guard let wallet = wallet, let amount = amount else {return nil}
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
                .drive(balanceView.balanceLabel.rx.text)
                .disposed(by: disposeBag)
            
            balanceTextDriver.map {$0 == nil}
                .drive(balanceView.walletView.rx.isHidden)
                .disposed(by: disposeBag)
            
            viewModel.errorDriver
                .map {($0 == L10n.insufficientFunds || $0 == L10n.yourAccountDoesNotHaveEnoughSOLToCoverFee || $0 == L10n.amountIsNotValid) ? UIColor.red: UIColor.h5887ff}
                .drive(balanceView.rx.tintColor)
                .disposed(by: disposeBag)
            
            // use all balance
            viewModel.useAllBalanceSignal
                .map {$0?.toString(maximumFractionDigits: 9, groupingSeparator: "")}
                .emit(onNext: {[weak self] amount in
                    self?.amountTextField.text = amount
                })
                .disposed(by: disposeBag)
        }
    }
}

private extension SendToken.WalletView {
    @objc func chooseWallet() {
        viewModel.navigate(to: .chooseWallet)
    }
    
    @objc func useAllBalance() {
        viewModel.useAllBalance()
    }
    
    @objc func switchCurrencyMode() {
        viewModel.switchCurrencyMode()
    }
}

extension SendToken.WalletView: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let textField = textField as? TokenAmountTextField {
            return textField.shouldChangeCharactersInRange(range, replacementString: string)
        }
        return true
    }
}
