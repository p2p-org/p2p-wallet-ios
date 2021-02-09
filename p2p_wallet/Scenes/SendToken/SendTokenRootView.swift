//
//  SendTokenRootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/02/2021.
//

import UIKit
import RxSwift

class SendTokenRootView: ScrollableVStackRootView {
    // MARK: - Constants
    
    // MARK: - Properties
    let viewModel: SendTokenViewModel
    let disposeBag = DisposeBag()
    
    // MARK: - Subviews
    lazy var balanceLabel = UILabel(text: "0", weight: .semibold, textColor: .h5887ff)
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
    lazy var changeModeButton = UILabel(textSize: 15, weight: .medium, textColor: .textSecondary)
        .onTap(viewModel, action: #selector(SendTokenViewModel.switchMode))
    lazy var symbolLabel = UILabel(textSize: 15, weight: .semibold)
    lazy var equityValueLabel = UILabel(text: "≈", textSize: 13, textColor: .textSecondary)
    lazy var coinSymbolPriceLabel = UILabel(textSize: 15, textColor: .textSecondary)
    lazy var coinPriceLabel = UILabel(textSize: 15, textColor: .textSecondary)
    lazy var addressTextView: UITextView = {
        let textView = UITextView(forExpandable: ())
        textView.backgroundColor = .clear
        textView.font = .systemFont(ofSize: 15)
        return textView
    }()
    lazy var qrCodeImageView = UIImageView(width: 18, height: 18, image: .scanQr, tintColor: UIColor.black.withAlphaComponent(0.5))
        .onTap(viewModel, action: #selector(SendTokenViewModel.scanQrCode))
    lazy var errorLabel = UILabel(text: " ", textSize: 12, weight: .medium, textColor: .red, numberOfLines: 0, textAlignment: .center)
    
    lazy var feeLabel = LazyLabel<Double>(textSize: 15, textColor: .textSecondary)
    
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
    
    func layout() {
        stackView.addArrangedSubviews([
            UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .equalSpacing, arrangedSubviews: [
                UILabel(text: L10n.from, weight: .bold),
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
                symbolLabel,
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
            
            UIStackView(axis: .vertical, spacing: 16, alignment: .fill, distribution: .fill, arrangedSubviews: [
                UILabel(text: L10n.sendTo, textSize: 15, weight: .bold),
                UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .fill, arrangedSubviews: [
                    addressTextView, qrCodeImageView
                ])
                    .padding(.init(all: .defaultPadding), backgroundColor: .c4c4c4, cornerRadius: 16)
            ]),
            BEStackViewSpacing(19),
            
            errorLabel
        ])
        
        equityValueLabel.autoPinEdge(.leading, to: .leading, of: amountTextField)
    }
    
    func bind() {
        amountTextField.rx.text
            .distinctUntilChanged()
            .map {$0 == nil ? nil: Double($0!)}
            .bind(to: viewModel.amountInput)
            .disposed(by: disposeBag)
        
        viewModel.amountInput
            .distinctUntilChanged()
            .map { $0 == nil ? nil: $0.toString(maximumFractionDigits: 9, groupingSeparator: nil) }
            .asDriver(onErrorJustReturn: nil)
            .drive(amountTextField.rx.text)
            .disposed(by: disposeBag)
        
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
        
        viewModel.currentWallet.distinctUntilChanged()
            .subscribe(onNext: {wallet in
                guard let wallet = wallet else {return}
                self.coinImageView.setUp(wallet: wallet)
            })
            .disposed(by: disposeBag)
        
        Observable.combineLatest(
            viewModel.currentWallet.distinctUntilChanged(),
            viewModel.isUSDMode.distinctUntilChanged(),
            viewModel.amountInput.distinctUntilChanged()
        )
            .map { (wallet, isUSDMode, amount) -> String in
                guard let wallet = wallet else {return ""}
                var equityValue = amount * wallet.priceInUSD
                var equityValueSymbol = "USD"
                if isUSDMode {
                    equityValue = amount / wallet.priceInUSD
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
        
        feeLabel.subscribed(to: viewModel.fee) {
            "\($0.toString(maximumFractionDigits: 9)) SOL"
        }
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
