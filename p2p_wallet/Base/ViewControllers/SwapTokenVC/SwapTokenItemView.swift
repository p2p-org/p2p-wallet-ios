//
//  SwapTokenItemView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2020.
//

import Foundation

class SwapTokenItemView: BEView {
    lazy var stackView = UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill)
    
    lazy var iconImageView = UIImageView(width: 44, height: 44, backgroundColor: .c4c4c4, cornerRadius: 22)
    
    lazy var tokenSymbolLabel = UILabel(text: "TOK", weight: .medium)
    
    lazy var amountTextField = TokenAmountTextField(font: .systemFont(ofSize: 27, weight: .semibold), textColor: .textBlack, keyboardType: .decimalPad, placeholder: "0\(Locale.current.decimalSeparator ?? ".")0", autocorrectionType: .no/*, rightView: useAllBalanceButton, rightViewMode: .always*/)
    
//    lazy var useAllBalanceButton = UIButton(label: L10n.max, labelFont: .systemFont(ofSize: 12, weight: .semibold), textColor: .secondary)
//        .onTap(self, action: #selector(buttonUseAllBalanceDidTouch))
    
    override func commonInit() {
        super.commonInit()
        
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
        
        let downArrowImage = UIImageView(width: 11, height: 8, image: .downArrow)
        downArrowImage.tintColor = .textBlack
        
        stackView.addArrangedSubviews([
            iconImageView,
            tokenSymbolLabel,
            downArrowImage,
            amountTextField
        ])
        
        tokenSymbolLabel.setContentHuggingPriority(.required, for: .horizontal)
        
        setUp(wallet: nil)
    }
    
    func setUp(wallet: Wallet?) {
        amountTextField.wallet = wallet
        if let wallet = wallet {
            tokenSymbolLabel.alpha = 1
            
            iconImageView.setImage(urlString: wallet.icon)
            tokenSymbolLabel.text = wallet.symbol
        } else {
            tokenSymbolLabel.alpha = 0
            
            iconImageView.image = nil
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
