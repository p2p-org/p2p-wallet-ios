//
//  SendTokenVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/12/20.
//

import Foundation

class SendTokenVC: BaseVStackVC {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
        .normal(backgroundColor: .vcBackground)
    }
    
    override var padding: UIEdgeInsets {UIEdgeInsets(top: 44, left: 16, bottom: 0, right: 16)}
    
    lazy var coinImageView = UIImageView(width: 44, height: 44, backgroundColor: .gray, cornerRadius: 22)
    lazy var amountTextField = UITextField(font: .systemFont(ofSize: 27, weight: .semibold), textColor: .textBlack, keyboardType: .numbersAndPunctuation, placeholder: L10n.amount, autocorrectionType: .no)
    
    override func setUp() {
        super.setUp()
        view.backgroundColor = .vcBackground
        title = L10n.sendCoins
        
        scrollView.contentView.backgroundColor = .textWhite
        scrollView.contentView.layer.cornerRadius = 16
        scrollView.contentView.layer.masksToBounds = true
        
        let amountView: UIStackView = {
            let stackView = UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill)
            let downArrowImage = UIImageView(width: 11, height: 8, image: .downArrow)
            downArrowImage.tintColor = .textBlack
            stackView.addArrangedSubviews([
                .spacer,
                coinImageView,
                downArrowImage,
                amountTextField,
                .spacer
            ])
            return stackView
        }()
        
        stackView.addArrangedSubviews([
            .spacer,
            amountView,
            .spacer
        ])
    }
}
