//
//  SendTokenItemVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/11/2020.
//

import Foundation
import RxSwift
import Action
import RxCocoa

class SendTokenItemVC: BaseVC {
    // MARK: - Properties
    var wallet: Wallet?
    lazy var dataDidChange = Observable.combineLatest(
        amountTextField.rx.text.orEmpty.map {$0.double ?? 0},
        addressTextView.rx.text.orEmpty,
        isUSDMode
    ).share()
    var chooseWalletAction: CocoaAction?
    let isUSDMode = BehaviorRelay<Bool>(value: false)
    
    // MARK: - Subviews
    lazy var balanceLabel = UILabel(text: "0", weight: .semibold, textColor: .h5887ff)
        .onTap(self, action: #selector(buttonUseAllBalanceDidTouch))
    lazy var coinImageView = CoinLogoImageView(width: 44, height: 44, cornerRadius: 12)
        .onTap(self, action: #selector(buttonChooseWalletDidTouch))
    lazy var amountTextField = TokenAmountTextField(
        font: .systemFont(ofSize: 27, weight: .semibold),
        textColor: .textBlack,
        keyboardType: .decimalPad,
        placeholder: "0\(Locale.current.decimalSeparator ?? ".")0",
        autocorrectionType: .no
    )
    lazy var changeModeButton = UILabel(textSize: 15, weight: .medium, textColor: .textSecondary)
        .onTap(self, action: #selector(modeSwitcherDidTouch))
    lazy var equityValueLabel = UILabel(text: "≈", textSize: 13, textColor: .textSecondary)
    lazy var addressTextView: UITextView = {
        let textView = UITextView(forExpandable: ())
        textView.backgroundColor = .clear
        textView.font = .systemFont(ofSize: 15)
        return textView
    }()
    lazy var qrCodeImageView = UIImageView(width: 18, height: 18, image: .scanQr, tintColor: UIColor.black.withAlphaComponent(0.5))
        .onTap(self, action: #selector(buttonScanQrCodeDidTouch))
    lazy var errorLabel = UILabel(text: " ", textSize: 12, weight: .medium, textColor: .red, numberOfLines: 0, textAlignment: .center)
    
    lazy var stackView = UIStackView(axis: .vertical, spacing: 16, alignment: .fill, distribution: .fill)
    
    lazy var feeLabel = LazyLabel<Double>(textSize: 15, textColor: .textSecondary)
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        view.backgroundColor = .clear
        view.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
        
        stackView.addArrangedSubviews([
            UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .equalSpacing, arrangedSubviews: [
                UILabel(text: L10n.from, weight: .bold),
                balanceLabel
            ]),
            BEStackViewSpacing(30),
            
            UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill, arrangedSubviews: [
                coinImageView,
                UIImageView(width: 11, height: 8, image: .downArrow, tintColor: .textBlack)
                    .onTap(self, action: #selector(buttonChooseWalletDidTouch)),
                amountTextField,
                changeModeButton
                    .withContentHuggingPriority(.required, for: .horizontal)
                    .padding(.init(all: 10), backgroundColor: .f6f6f8, cornerRadius: 12)
            ]),
            BEStackViewSpacing(6),
            
            UIStackView(axis: .horizontal, spacing: 0, alignment: .center, distribution: .fill, arrangedSubviews: [
                UILabel(text: wallet?.symbol, textSize: 15, weight: .semibold)
                    .padding(UIEdgeInsets.zero.modifying(dLeft: 8)),
                equityValueLabel
            ]),
            BEStackViewSpacing(20),
            
            UIView.separator(height: 1, color: .separator),
            BEStackViewSpacing(20),
            
            UIView.col([
                .row([
                    UILabel(text: "1 " + (wallet?.symbol ?? "") + ":", textSize: 15, textColor: .textSecondary),
                    UILabel(text: (wallet?.price?.value?.toString(maximumFractionDigits: 9) ?? "") + " US$", textSize: 15, textColor: .textSecondary)
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
        
        amountTextField.delegate = self
    }
    
    func setUp(wallet: Wallet) {
        self.wallet = wallet
        coinImageView.setUp(wallet: wallet)
    }
    
    override func bind() {
        super.bind()
        
        dataDidChange
            .skip(1)
            .subscribe(onNext: {(_, _, isUSDMode) in
                guard let wallet = self.wallet else {return}
                
                // balance label
                var balanceLabelText = L10n.available + ": "
                
                // calculate available amount
                var amount = wallet.amount ?? 0
                var fee = FeeVM.shared.data
                var symbol = wallet.symbol
                if isUSDMode {
                    amount = wallet.amountInUSD
                    fee = fee * wallet.priceInUSD
                    symbol = "USD"
                }
                amount = amount - fee
                if amount < 0 { amount = 0 }
                
                // set label
                balanceLabelText += amount.toString(maximumFractionDigits: 9)
                balanceLabelText += " \(symbol)"
                self.balanceLabel.text = balanceLabelText
                
                // equity value label
                var equityValue = self.amountTextField.value * wallet.priceInUSD
                var equityValueSymbol = "USD"
                if isUSDMode {
                    if let price = wallet.priceInUSD,
                       price != 0 {
                        equityValue = self.amountTextField.value / price
                    }
                    
                    equityValueSymbol = wallet.symbol
                }
                self.equityValueLabel.text = equityValue.toString(maximumFractionDigits: 9) + " " + equityValueSymbol
                
                // change mode button
                self.changeModeButton.text = symbol
                
                // validate error
                self.handleError()
            })
            .disposed(by: disposeBag)
        
        feeLabel
            .subscribed(to: FeeVM.shared) {
                $0.toString(maximumFractionDigits: 9) + " SOL"
            }
            .disposed(by: disposeBag)
    }
    
    private func handleError() {
        guard let wallet = wallet else {return}
        var errorMessage: String?
        if amountTextField.value <= 0 {
            errorMessage = L10n.amountIsNotValid
        } else {
            let amount = amountTextField.value
            let amountToCompare = isUSDMode.value ? wallet.amountInUSD: wallet.amount
            
            if amount > amountToCompare {
                errorMessage = L10n.insufficientFunds
            } else if !NSRegularExpression.publicKey.matches(addressTextView.text)
            {
                errorMessage = L10n.theAddressIsNotValid
            }
        }
        
        if let errorMessage = errorMessage {
            errorLabel.text = errorMessage
        } else {
            errorLabel.text = " "
        }
    }
    
    var isDataValid: Bool {
        errorLabel.text == " "
    }
    
    // MARK: - Actions
    @objc func modeSwitcherDidTouch() {
        isUSDMode.accept(!isUSDMode.value)
    }
    
    @objc func buttonScanQrCodeDidTouch() {
        let vc = QrCodeScannerVC()
        vc.callback = { code in
            if NSRegularExpression.publicKey.matches(code) {
                self.addressTextView.text = code
                return true
            }
            return false
        }
        vc.modalPresentationStyle = .custom
        parent?.present(vc, animated: true, completion: nil)
    }
    
    @objc func buttonUseAllBalanceDidTouch() {
        guard let wallet = wallet else {return}
        let allBalance = isUSDMode.value ? wallet.amountInUSD: (wallet.amount ?? 0)
        var fee = FeeVM.shared.data
        if isUSDMode.value {
            fee = fee * wallet.priceInUSD
        }
        let amountToUse = allBalance - fee
        if amountToUse > 0 {
            amountTextField.text = amountToUse.toString(maximumFractionDigits: 9, groupingSeparator: nil)
            amountTextField.sendActions(for: .valueChanged)
        }
    }
    
    @objc func buttonChooseWalletDidTouch() {
        chooseWalletAction?.execute()
    }
}

extension SendTokenItemVC: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let textField = textField as? TokenAmountTextField {
            return textField.shouldChangeCharactersInRange(range, replacementString: string)
        }
        return true
    }
}
