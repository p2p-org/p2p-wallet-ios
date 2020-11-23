//
//  SendTokenItemVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/11/2020.
//

import Foundation
import RxSwift

class SendTokenItemVC: BaseVC {
    // MARK: - Properties
    var wallet: Wallet?
    lazy var dataObservable = Observable.combineLatest(
        amountTextField.rx.text.orEmpty.map {$0.double ?? 0},
        addressTextView.rx.text.orEmpty
    ).share()
    
    // MARK: - Subviews
    lazy var tokenNameLabel = UILabel(text: "TOKEN", weight: .semibold)
    lazy var balanceLabel = UILabel(text: "0", weight: .semibold, textColor: .secondary)
    lazy var coinImageView = UIImageView(width: 44, height: 44, cornerRadius: 22)
    lazy var amountTextField = BEDecimalTextField(font: .systemFont(ofSize: 27, weight: .semibold), textColor: .textBlack, keyboardType: .decimalPad, placeholder: "0\(Locale.current.decimalSeparator ?? ".")0", autocorrectionType: .no, rightView: useAllBalanceButton, rightViewMode: .always)
    lazy var useAllBalanceButton = UIButton(label: L10n.max, labelFont: .systemFont(ofSize: 12, weight: .semibold), textColor: .secondary)
        .onTap(self, action: #selector(buttonUseAllBalanceDidTouch))
    lazy var equityValueLabel = UILabel(text: "=", textSize: 13, textColor: .secondary)
    lazy var addressTextView: UITextView = {
        let textView = UITextView(forExpandable: ())
        textView.backgroundColor = .clear
        textView.font = .systemFont(ofSize: 15)
        return textView
    }()
    lazy var qrCodeImageView = UIImageView(width: 18, height: 18, image: .scanQr, tintColor: UIColor.black.withAlphaComponent(0.5))
        .onTap(self, action: #selector(buttonScanQrCodeDidTouch))
    lazy var errorLabel = UILabel(text: "Error: ", textSize: 12, weight: .medium, textColor: .red, numberOfLines: 0, textAlignment: .center)
    
    lazy var stackView = UIStackView(axis: .vertical, spacing: 16, alignment: .fill, distribution: .fill)
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        view.backgroundColor = .clear
        view.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
        
        let tokenInfoView: UIStackView = {
            let stackView = UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .equalSpacing)
            stackView.addArrangedSubview(tokenNameLabel)
            stackView.addArrangedSubview(balanceLabel)
            return stackView
        }()
        
        let amountView: UIStackView = {
            let stackView = UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill)
            let downArrowImage = UIImageView(width: 11, height: 8, image: .downArrow)
            downArrowImage.tintColor = .textBlack
            
            let amountVStack: UIStackView = {
                let stackView = UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill)
                stackView.addArrangedSubviews([.spacer, amountTextField, equityValueLabel])
                return stackView
            }()
            
            stackView.addArrangedSubviews([
                coinImageView,
                downArrowImage,
                amountVStack
            ])
            amountTextField.autoAlignAxis(.horizontal, toSameAxisOf: coinImageView)
            return stackView
        }()
        
        let separator = UIView.separator(height: 2, color: .vcBackground)
        
        let addressView: UIStackView = {
            let stackView = UIStackView(axis: .vertical, spacing: 16, alignment: .fill, distribution: .fill)
            let containerView: UIView = {
                let view = UIView(backgroundColor: .c4c4c4, cornerRadius: 16)
                let stackView = UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .fill)
                view.addSubview(stackView)
                stackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(all: 20))
                stackView.addArrangedSubviews([addressTextView, qrCodeImageView])
                return view
            }()
            stackView.addArrangedSubviews([
                UILabel(text: L10n.walletAddress, textSize: 15, weight: .semibold),
                containerView
            ])
            return stackView
        }()
        
        stackView.addArrangedSubviews([
            .spacer,
            tokenInfoView.padding(UIEdgeInsets(x: 16, y: 0)),
            amountView.padding(UIEdgeInsets(x: 16, y: 0)),
            separator,
            addressView.padding(UIEdgeInsets(x: 16, y: 0)),
            errorLabel.padding(UIEdgeInsets(x: 16, y: 0)),
            .spacer
        ])
        stackView.setCustomSpacing(16, after: tokenInfoView.wrapper!)
        stackView.setCustomSpacing(30, after: separator)
        stackView.setCustomSpacing(16, after: addressView)
        
        errorLabel.isHidden = true
        
        amountTextField.delegate = self
    }
    
    func setUp(wallet: Wallet) {
        self.wallet = wallet
        tokenNameLabel.text = wallet.name
        balanceLabel.text = "\(wallet.amount?.toString(maximumFractionDigits: 9) ?? "") \(wallet.symbol)"
        coinImageView.setImage(urlString: wallet.icon)
    }
    
    override func bind() {
        super.bind()
        amountTextField.rx.text.orEmpty
            .map {$0.double ?? 0}
            .map {$0 * self.wallet?.price?.value}
            .map {"= " + $0.toString(maximumFractionDigits: 9) + " US$"}
            .asDriver(onErrorJustReturn: "")
            .drive(equityValueLabel.rx.text)
            .disposed(by: disposeBag)
        
        dataObservable
            .skip(1)
            .subscribe(onNext: {(amount, address) in
                self.validate(amount: amount, address: address)
            })
            .disposed(by: disposeBag)
    }
    
    private func validate(amount: Double, address: String) {
        var errorMessage: String?
        if amount <= 0 {
            errorMessage = L10n.amountIsNotValid
        } else if amount > (wallet?.amount ?? Double.greatestFiniteMagnitude) {
            errorMessage = L10n.insufficientFunds
        } else if !NSRegularExpression.publicKey.matches(address) {
            errorMessage = L10n.theAddressIsNotValid
        }
        
        if let errorMessage = errorMessage {
            errorLabel.text = errorMessage
            errorLabel.isHidden = false
        } else {
            errorLabel.text = nil
            errorLabel.isHidden = true
        }
    }
    
    var isDataValid: Bool {
        let amount = amountTextField.text?.double ?? 0
        return amount > 0 && amount <= (wallet?.amount ?? 0) && NSRegularExpression.publicKey.matches(addressTextView.text ?? "")
    }
    
    // MARK: - Actions
    @objc func buttonScanQrCodeDidTouch() {
        let vc = QrCodeScannerVC()
        vc.validate = { code in
            NSRegularExpression.publicKey.matches(code)
        }
        vc.completion = { code in
            self.addressTextView.text = code
        }
        vc.modalPresentationStyle = .custom
        parent?.present(vc, animated: true, completion: nil)
    }
    
    @objc func buttonUseAllBalanceDidTouch() {
        amountTextField.text = wallet?.amount?.toString(maximumFractionDigits: 9)
        amountTextField.sendActions(for: .valueChanged)
    }
}

extension SendTokenItemVC: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let textField = textField as? BEDecimalTextField {
            // get the current text, or use an empty string if that failed
            let currentText = textField.text ?? ""
            
            guard textField.shouldChangeCharactersInRange(range, replacementString: string),
                  let stringRange = Range(range, in: currentText)
            else {
                return false
            }
            // add their new text to the existing text
            var updatedText = currentText.replacingCharacters(in: stringRange, with: string)
            if let dotIndex = updatedText.firstIndex(of: Locale.current.decimalSeparator?.first ?? ".") {
                let offset = updatedText.distance(from: dotIndex, to: updatedText.endIndex) - 1
                let decimals = wallet?.decimals ?? 0
                if offset > decimals {
                    let endIndex = updatedText.index(dotIndex, offsetBy: decimals)
                    updatedText = String(updatedText[updatedText.startIndex...endIndex])
                    textField.text = updatedText
                    return false
                }
            }
            
            return true
        }
        return true
    }
}
