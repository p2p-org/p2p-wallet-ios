//
//  SendTokenRootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/02/2021.
//

import UIKit
import RxSwift
import RxBiBinding

class SendTokenRootView: ScrollableVStackRootView {
    // MARK: - Constants
    
    // MARK: - Properties
    let viewModel: SendTokenViewModel
    let disposeBag = DisposeBag()
    
    // MARK: - Subviews
    lazy var balanceLabel = UILabel(text: "0", textSize: 15, weight: .medium)
        .onTap(viewModel, action: #selector(SendTokenViewModel.useAllBalance))
    lazy var coinImageView = CoinLogoImageView(width: 44, height: 44, cornerRadius: 12)
        .onTap(viewModel, action: #selector(SendTokenViewModel.chooseWallet))
    lazy var amountTextField = TokenAmountTextField(
        font: .systemFont(ofSize: 27, weight: .semibold),
        textColor: .textBlack,
        keyboardType: .decimalPad,
        placeholder: "0\(Locale.current.decimalSeparator ?? ".")0",
        autocorrectionType: .no
    )
    lazy var changeModeButton = UILabel(textSize: 15, weight: .semibold, textColor: .textSecondary)
        .onTap(viewModel, action: #selector(SendTokenViewModel.switchMode))
    lazy var symbolLabel = UILabel(textSize: 15, weight: .semibold)
    lazy var equityValueLabel = UILabel(text: "≈", textSize: 15, textColor: .textSecondary)
    lazy var coinSymbolPriceLabel = UILabel(textSize: 15, textColor: .textSecondary)
    lazy var coinPriceLabel = UILabel(textSize: 15, textColor: .textSecondary)
    
    lazy var addressStackView = UIStackView(axis: .horizontal, spacing: 0, alignment: .center, distribution: .fill, arrangedSubviews: [
        walletIconView, addressTextField, clearAddressButton, qrCodeImageView
    ])
    lazy var walletIconView = UIImageView(width: 24, height: 24, image: .walletIcon, tintColor: .a3a5ba)
        .padding(.init(all: 10), backgroundColor: .textWhite, cornerRadius: 12)
    lazy var addressTextField = UITextField(height: 44, backgroundColor: .clear, placeholder: L10n.walletAddress, autocorrectionType: .none, autocapitalizationType: UITextAutocapitalizationType.none, spellCheckingType: .no, horizontalPadding: 8)
    lazy var clearAddressButton = UIImageView(width: 24, height: 24, image: .closeFill, tintColor: UIColor.black.withAlphaComponent(0.6))
        .onTap(viewModel, action: #selector(SendTokenViewModel.clearDestinationAddress))
    lazy var qrCodeImageView = UIImageView(width: 35, height: 35, image: .scanQr3, tintColor: .a3a5ba)
        .onTap(viewModel, action: #selector(SendTokenViewModel.scanQrCode))
    lazy var errorLabel = UILabel(text: " ", textSize: 12, weight: .medium, textColor: .red, numberOfLines: 0, textAlignment: .center)
    
    lazy var feeLabel = LazyLabel<Double>(textSize: 15, textColor: .textSecondary)
    
    lazy var sendButton = WLButton.stepButton(type: .blue, label: L10n.sendNow)
        .onTap(viewModel, action: #selector(SendTokenViewModel.send))
    
    // MARK: - Initializers
    init(viewModel: SendTokenViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
    }
    
    // MARK: - Methods
    override func commonInit() {
        super.commonInit()
        // layout
        layout()
        
        // bind view model
        bind()
        
        amountTextField.delegate = self
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        amountTextField.becomeFirstResponder()
    }
    
    func layout() {
        stackView.addArrangedSubviews([
            UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .equalSpacing, arrangedSubviews: [
                UILabel(text: L10n.from, textSize: 15, weight: .bold),
                balanceLabel
            ]),
            BEStackViewSpacing(30),
            
            UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill, arrangedSubviews: [
                coinImageView,
                UIImageView(width: 11, height: 8, image: .downArrow, tintColor: .textBlack)
                    .onTap(viewModel, action: #selector(SendTokenViewModel.chooseWallet)),
                amountTextField,
                changeModeButton
                    .withContentHuggingPriority(.required, for: .horizontal)
                    .padding(.init(all: 10), backgroundColor: .f6f6f8, cornerRadius: 12)
            ]),
            BEStackViewSpacing(6),
            
            UIStackView(axis: .horizontal, spacing: 0, alignment: .center, distribution: .fill, arrangedSubviews: [
                UIView(),
                equityValueLabel
            ]),
            BEStackViewSpacing(20),
            
            UIView.separator(height: 1, color: .separator),
            BEStackViewSpacing(20),
            
            UIView.col([
                .row([
                    coinSymbolPriceLabel,
                    coinPriceLabel
                ]),
                .row([
                    UILabel(text: L10n.fee + ":", textSize: 15, textColor: .textSecondary),
                    feeLabel
                ])
            ]),
            BEStackViewSpacing(20),
            
            UIView.separator(height: 1, color: .separator),
            BEStackViewSpacing(20),
            
            UILabel(text: L10n.sendTo, textSize: 15, weight: .bold),
            addressStackView
                .padding(.init(all: 8), backgroundColor: UIColor.a3a5ba.withAlphaComponent(0.1), cornerRadius: 12),
            
            BEStackViewSpacing(19),
            
            errorLabel,
            
            BEStackViewSpacing(20),
            UIView.separator(height: 1, color: .separator),
            BEStackViewSpacing(20),
            
            sendButton
        ])
        
        equityValueLabel.autoPinEdge(.leading, to: .leading, of: amountTextField)
        
        addSubview(symbolLabel)
        symbolLabel.centerXAnchor.constraint(equalTo: coinImageView.centerXAnchor).isActive = true
        symbolLabel.centerYAnchor.constraint(equalTo: equityValueLabel.centerYAnchor).isActive = true
    }
    
    func bind() {
        // amount text field
        (amountTextField.rx.text <-> viewModel.amountInput)
            .disposed(by: disposeBag)
        (addressTextField.rx.text <-> viewModel.destinationAddressInput)
            .disposed(by: disposeBag)
        
        // available amount
        viewModel.availableAmount
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: 0)
            .drive(onNext: {availableAmount in
                guard let symbol = self.viewModel.isUSDMode.value ? "USD": self.viewModel.currentWallet.value?.symbol
                else {return}
                self.balanceLabel.text =
                    L10n.available +
                    ": " +
                    availableAmount.toString(maximumFractionDigits: 9) +
                    " " +
                    symbol
            })
            .disposed(by: disposeBag)
        
        // available amount color
        viewModel.errorSubject
            .map {($0 == L10n.insufficientFunds || $0 == L10n.yourAccountDoesNotHaveEnoughSOLToCoverFee) ? UIColor.red: UIColor.h5887ff}
            .subscribe(onNext: {color in
                self.balanceLabel.textColor = color
            })
            .disposed(by: disposeBag)
        
        // current wallet
        viewModel.currentWallet.distinctUntilChanged()
            .subscribe(onNext: {wallet in
                guard let wallet = wallet else {return}
                self.coinImageView.setUp(wallet: wallet)
                self.symbolLabel.text = wallet.symbol
            })
            .disposed(by: disposeBag)
        
        Observable.combineLatest(
            viewModel.currentWallet.distinctUntilChanged(),
            viewModel.isUSDMode.distinctUntilChanged(),
            viewModel.amountInput.distinctUntilChanged()
        )
            .map { (wallet, isUSDMode, amount) -> String in
                guard let wallet = wallet else {return ""}
                var equityValue = amount.double * wallet.priceInUSD
                var equityValueSymbol = "USD"
                if isUSDMode {
                    equityValue = amount.double / wallet.priceInUSD
                    equityValueSymbol = wallet.symbol
                }
                return "≈ " + equityValue.toString(maximumFractionDigits: 9) + " " + equityValueSymbol
            }
            .asDriver(onErrorJustReturn: "")
            .drive(equityValueLabel.rx.text)
            .disposed(by: disposeBag)
        
        Observable.combineLatest(
            viewModel.currentWallet.distinctUntilChanged(),
            viewModel.isUSDMode.distinctUntilChanged()
        )
            .map { $0.1 ? "USD": ($0.0?.symbol ?? "")}
            .asDriver(onErrorJustReturn: "")
            .drive(changeModeButton.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.currentWallet.distinctUntilChanged()
            .map {$0?.symbol ?? ""}
            .asDriver(onErrorJustReturn: "")
            .map {"1 \($0):"}
            .drive(coinSymbolPriceLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.currentWallet.distinctUntilChanged()
            .map {$0?.priceInUSD ?? 0}
            .asDriver(onErrorJustReturn: 0)
            .map {"\($0.toString(maximumFractionDigits: 9)) US$"}
            .drive(coinPriceLabel.rx.text)
            .disposed(by: disposeBag)
        
        // fee
        feeLabel.subscribed(to: viewModel.fee) {
            "\($0.toString(maximumFractionDigits: 9)) SOL"
        }
            .disposed(by: disposeBag)
        
        // input to address textfield
        let destinationAddressInput = viewModel.destinationAddressInput
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: nil)
        
        destinationAddressInput
            .map {_ in !self.viewModel.isDestinationWalletValid()}
            .drive(walletIconView.rx.isHidden)
            .disposed(by: disposeBag)
        
        let destinationAddressInputEmpty = destinationAddressInput
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
        viewModel.errorSubject
            .map {
                if $0 == L10n.insufficientFunds {
                    return nil
                }
                return $0
            }
            .asDriver(onErrorJustReturn: nil)
            .drive(errorLabel.rx.text)
            .disposed(by: disposeBag)
        
        // send button
        viewModel.errorSubject.map {$0 == nil}
            .asDriver(onErrorJustReturn: false)
            .drive(sendButton.rx.isEnabled)
            .disposed(by: disposeBag)
    }
}

extension SendTokenRootView: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let textField = textField as? TokenAmountTextField {
            return textField.shouldChangeCharactersInRange(range, replacementString: string)
        }
        return true
    }
}
