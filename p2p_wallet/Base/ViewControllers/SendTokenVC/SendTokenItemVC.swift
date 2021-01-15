//
//  SendTokenItemVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/11/2020.
//

import Foundation
import RxSwift
import Action

class SendTokenItemVC: BaseVC {
    // MARK: - Properties
    var wallet: Wallet?
    lazy var dataObservable = Observable.combineLatest(
        amountTextField.rx.text.orEmpty.map {$0.double ?? 0},
        addressTextView.rx.text.orEmpty
    ).share()
    var chooseWalletAction: CocoaAction?
    var price: Double {wallet?.price?.value ?? 0}
    var textFieldValue: Double {amountTextField.text.map {$0.double ?? 0} ?? 0}
    var textFieldValueInToken: Double {price != 0 ? textFieldValue / price: 0}
    
    // MARK: - Subviews
    lazy var balanceLabel = UILabel(text: "0", textColor: .h5887ff)
        .onTap(self, action: #selector(buttonUseAllBalanceDidTouch))
    lazy var coinImageView = CoinLogoImageView(width: 44, height: 44, cornerRadius: 22)
        .onTap(self, action: #selector(buttonChooseWalletDidTouch))
    lazy var amountTextField = TokenAmountTextField(
        font: .systemFont(ofSize: 27, weight: .semibold),
        textColor: .textBlack,
        keyboardType: .decimalPad,
        placeholder: "0\(Locale.current.decimalSeparator ?? ".")0",
        autocorrectionType: .no
    )
    lazy var equityValueLabel = UILabel(text: "=", textSize: 13, textColor: .textSecondary)
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
    
    lazy var feeLabel = LazyLabel<Double>(textSize: 15)
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        view.backgroundColor = .clear
        view.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
        
        stackView.addArrangedSubviews([
            UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .equalSpacing, arrangedSubviews: [
                UILabel(text: L10n.from, weight: .medium),
                balanceLabel
            ]),
            BEStackViewSpacing(30),
            
            UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill, arrangedSubviews: [
                coinImageView,
                UIImageView(width: 11, height: 8, image: .downArrow, tintColor: .textBlack)
                    .onTap(self, action: #selector(buttonChooseWalletDidTouch)),
                amountTextField,
                UILabel(text: "USD", textSize: 15, weight: .medium, textColor: .textSecondary)
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
                    UILabel(text: "1 " + (wallet?.symbol ?? "") + ":", textSize: 15),
                    UILabel(text: (wallet?.price?.value?.toString(maximumFractionDigits: 9) ?? "") + " US$", textSize: 15)
                ]),
                .row([
                    UILabel(text: L10n.fee + ":", textSize: 15),
                    feeLabel
                ])
            ]),
            BEStackViewSpacing(20),
            
            UIView.separator(height: 1, color: .separator),
            BEStackViewSpacing(20),
            
            UIStackView(axis: .vertical, spacing: 16, alignment: .fill, distribution: .fill, arrangedSubviews: [
                UILabel(text: L10n.to, textSize: 15, weight: .semibold),
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
        balanceLabel.text = "\(L10n.available): \(wallet.amount.toString(maximumFractionDigits: 9)) \(wallet.symbol)"
        coinImageView.setUp(wallet: wallet)
    }
    
    override func bind() {
        super.bind()
        amountTextField.rx.text.orEmpty
            .map {_ in self.textFieldValueInToken}
            .map {"≈ " + $0.toString(maximumFractionDigits: 9) + " \(self.wallet?.symbol ?? "")"}
            .asDriver(onErrorJustReturn: "")
            .drive(equityValueLabel.rx.text)
            .disposed(by: disposeBag)
        
        dataObservable
            .skip(1)
            .subscribe(onNext: {(amount, address) in
                self.validate(amountInUSD: amount, address: address)
            })
            .disposed(by: disposeBag)
        
        feeLabel
            .subscribed(to: FeeVM.shared) {
                $0.toString(maximumFractionDigits: 9) + " SOL"
            }
            .disposed(by: disposeBag)
    }
    
    private func validate(amountInUSD: Double, address: String) {
        var errorMessage: String?
        if amountInUSD <= 0 {
            errorMessage = L10n.amountIsNotValid
        } else if (price != 0 ? amountInUSD / price : 0) > (wallet?.amount ?? Double.greatestFiniteMagnitude) {
            errorMessage = L10n.insufficientFunds
        } else if !NSRegularExpression.publicKey.matches(address) {
            errorMessage = L10n.theAddressIsNotValid
        }
        
        if let errorMessage = errorMessage {
            errorLabel.text = errorMessage
        } else {
            errorLabel.text = " "
        }
    }
    
    var isDataValid: Bool {
        textFieldValueInToken > 0 && textFieldValueInToken <= (wallet?.amount ?? 0) && NSRegularExpression.publicKey.matches(addressTextView.text ?? "")
    }
    
    // MARK: - Actions
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
        guard let token = wallet?.amount else {return}
        let amountInUSD = token * price
        
        amountTextField.text = amountInUSD.toString(maximumFractionDigits: 9)
        amountTextField.sendActions(for: .valueChanged)
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
