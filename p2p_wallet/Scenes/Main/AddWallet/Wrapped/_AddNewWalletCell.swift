//
//  _AddNewWalletCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/02/2021.
//

import Foundation
import RxSwift
import Action
import LazySubject

class _AddNewWalletCell: WalletCell {
    private let disposeBag = DisposeBag()
    lazy var symbolLabel = UILabel(text: "SER", textSize: 17, weight: .bold)
    
    lazy var mintAddressLabel = UILabel(weight: .semibold, numberOfLines: 0)
    lazy var viewInBlockchainExplorerButton = UIButton(label: L10n.viewInBlockchainExplorer, labelFont: .systemFont(ofSize: 15, weight: .semibold), textColor: .a3a5ba)
    
    lazy var buttonAddToken = WLAddTokenButton()
    
    lazy var errorLabel = UILabel(textSize: 13, textColor: .red, numberOfLines: 0, textAlignment: .center)
    
    lazy var detailView = UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill, arrangedSubviews: [
        UIView.separator(height: 1, color: .separator),
        BEStackViewSpacing(20),
        UILabel(text: L10n.mintAddress, textSize: 13, weight: .medium, textColor: .textSecondary, numberOfLines: 0),
        BEStackViewSpacing(5),
        mintAddressLabel,
        BEStackViewSpacing(20),
        UIView.separator(height: 1, color: .separator),
        BEStackViewSpacing(20),
        viewInBlockchainExplorerButton,
        BEStackViewSpacing(20),
        buttonAddToken
            .onTap(self, action: #selector(buttonCreateWalletDidTouch)),
        BEStackViewSpacing(16),
        errorLabel
    ])
    
    var createWalletAction: CocoaAction?
    
    override func commonInit() {
        super.commonInit()
        
        coinNameLabel.font = .systemFont(ofSize: 12, weight: .medium)
        coinNameLabel.textColor = .textSecondary
        
        coinPriceLabel.font = .systemFont(ofSize: 17, weight: .bold)
        
        coinChangeLabel.font = .systemFont(ofSize: 12, weight: .medium)
        
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.addArrangedSubviews([
            UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill, arrangedSubviews: [
                coinLogoImageView,
                UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill, arrangedSubviews: [
                    UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing, arrangedSubviews: [
                        symbolLabel,
                        coinPriceLabel
                    ]),
                    UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing, arrangedSubviews: [
                        coinNameLabel,
                        coinChangeLabel
                    ])
                ])
            ]),
            BEStackViewSpacing(16),
            detailView
        ])
        
        stackView.constraintToSuperviewWithAttribute(.bottom)?.isActive = false
        let separator = UIView.separator(height: 2, color: .vcBackground)
        stackView.superview?.addSubview(separator)
        separator.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        separator.autoPinEdge(.top, to: .bottom, of: stackView, withOffset: 20)
        
        stackView.constraintToSuperviewWithAttribute(.top)?.constant = 10
        stackView.constraintToSuperviewWithAttribute(.leading)?.constant = 20
        stackView.constraintToSuperviewWithAttribute(.trailing)?.constant = -20
    }
    
    override func setUp(with item: Wallet) {
        super.setUp(with: item)
        symbolLabel.text = item.symbol
        detailView.isHidden = !(item.isExpanded ?? false)
        mintAddressLabel.text = item.mintAddress
        contentView.backgroundColor = item.isExpanded == true ? .f6f6f8 : .clear
        
        buttonAddToken.setUp(with: item)
        
        if item.creatingError != nil {
            errorLabel.isHidden = false
            errorLabel.text = L10n.WeCouldnTAddATokenToYourWallet.checkYourInternetConnectionAndTryAgain
        } else {
            errorLabel.isHidden = true
        }
    }
    
    @objc func buttonCreateWalletDidTouch() {
        if buttonAddToken.isLoading {
            return
        }
        createWalletAction?.execute()
    }
}
