//
//  SwapTokenItemView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2020.
//

import Foundation

class SwapTokenItemView: BEView {
    lazy var iconImageView = CoinLogoImageView(width: 44, height: 44, cornerRadius: 12)
    
    lazy var tokenSymbolLabel = UILabel(text: "TOK", weight: .semibold, textAlignment: .center)
    
    lazy var amountTextField = TokenAmountTextField(font: .systemFont(ofSize: 27, weight: .semibold), textColor: .textBlack, keyboardType: .decimalPad, placeholder: "0\(Locale.current.decimalSeparator ?? ".")0", autocorrectionType: .no/*, rightView: useAllBalanceButton, rightViewMode: .always*/)
    
    lazy var equityValueLabel = UILabel(text: "≈ 0.00 $", textColor: .textSecondary)
    
//    lazy var useAllBalanceButton = UIButton(label: L10n.max, labelFont: .systemFont(ofSize: 12, weight: .semibold), textColor: .secondary)
//        .onTap(self, action: #selector(buttonUseAllBalanceDidTouch))
    
    override func commonInit() {
        super.commonInit()
        let stackView = UIStackView(axis: .vertical, spacing: 6, alignment: .fill, distribution: .fill, arrangedSubviews: [
            UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill, arrangedSubviews: [
                iconImageView,
                UIImageView(width: 11, height: 8, image: .downArrow, tintColor: .textSecondary),
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
        equityValueLabel.leadingAnchor.constraint(equalTo: amountTextField.leadingAnchor)
            .isActive = true
        
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
    }
    
    func setUp(wallet: Wallet?) {
        amountTextField.wallet = wallet
        if let wallet = wallet {
            tokenSymbolLabel.alpha = 1
            
            iconImageView.setUp(wallet: wallet)
            tokenSymbolLabel.text = wallet.symbol
        } else {
            tokenSymbolLabel.alpha = 0
            
            iconImageView.imageView.image = nil
            tokenSymbolLabel.text = "TOK"
        }
        amountTextField.text = nil
        amountTextField.sendActions(for: .valueChanged)
    }
    
//    @objc func buttonUseAllBalanceDidTouch() {
//        amountTextField.text = wallet?.amount?.toString(maximumFractionDigits: 9)
//        amountTextField.sendActions(for: .valueChanged)
//    }
}
