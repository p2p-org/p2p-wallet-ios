//
//  SwapTokenItemView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2020.
//

import Foundation
import Action
import RxSwift

class SwapTokenWalletView: BEView {
    var wallet: Wallet?
    let disposeBag = DisposeBag()
    
    lazy var iconImageView = CoinLogoImageView(size: 44)
        .with(placeholder: UIImageView(image: .walletPlaceholder))
    
    lazy var tokenSymbolLabel = UILabel(text: "TOK", weight: .semibold, textAlignment: .center)
    
    lazy var amountTextField = TokenAmountTextField(
        font: .systemFont(ofSize: 27, weight: .semibold),
        textColor: .textBlack,
        keyboardType: .decimalPad,
        placeholder: "0\(Locale.current.decimalSeparator ?? ".")0",
        autocorrectionType: .no/*, rightView: useAllBalanceButton, rightViewMode: .always*/
    )
    
    lazy var equityValueLabel = UILabel(text: "≈ 0.00 $", weight: .semibold, textColor: .textSecondary)
    
//    lazy var useAllBalanceButton = UIButton(label: L10n.max, labelFont: .systemFont(ofSize: 12, weight: .semibold), textColor: .secondary)
//        .onTap(self, action: #selector(buttonUseAllBalanceDidTouch))
    var chooseTokenAction: CocoaAction?
    
    override func commonInit() {
        super.commonInit()
        let stackView = UIStackView(axis: .vertical, spacing: 6, alignment: .fill, distribution: .fill, arrangedSubviews: [
            UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill, arrangedSubviews: [
                iconImageView
                    .onTap(self, action: #selector(buttonSelectTokenDidTouch)),
                UIImageView(width: 11, height: 8, image: .downArrow, tintColor: .a3a5ba)
                    .onTap(self, action: #selector(buttonSelectTokenDidTouch)),
                amountTextField
            ]),
            UIStackView(axis: .horizontal, spacing: 0, alignment: .center, distribution: .fill, arrangedSubviews: [
                tokenSymbolLabel
                    .withContentHuggingPriority(.required, for: .horizontal),
                UIView.spacer,
                equityValueLabel
            ])
        ])
        
        tokenSymbolLabel.centerXAnchor.constraint(equalTo: iconImageView.centerXAnchor)
            .isActive = true
        tokenSymbolLabel.adjustsFontSizeToFitWidth = true
        equityValueLabel.leadingAnchor.constraint(equalTo: amountTextField.leadingAnchor)
            .isActive = true
        
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
    }
    
    func setUp(wallet: Wallet?) {
        amountTextField.wallet = wallet
        iconImageView.setUp(wallet: wallet)
        if let wallet = wallet {
            tokenSymbolLabel.alpha = 1
            tokenSymbolLabel.text = wallet.symbol
        } else {
            tokenSymbolLabel.alpha = 0
            tokenSymbolLabel.text = nil
        }
        
        self.wallet = wallet
    }
    
    @objc func buttonSelectTokenDidTouch() {
        chooseTokenAction?.execute()
    }
    
//    @objc func buttonUseAllBalanceDidTouch() {
//        amountTextField.text = wallet?.amount?.toString(maximumFractionDigits: 9)
//        amountTextField.sendActions(for: .valueChanged)
//    }
}
