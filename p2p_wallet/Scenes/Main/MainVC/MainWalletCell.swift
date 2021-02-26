//
//  PriceCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/2/20.
//

import Foundation
import Action

class EditableWalletCell: WalletCell {
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView(forAutoLayout: ())
        scrollView.isPagingEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    lazy var buttonStackView = UIStackView(axis: .horizontal, spacing: 16, alignment: .fill, distribution: .fill)
    lazy var editButton = UIImageView(width: 24, height: 24, image: .walletEdit, tintColor: .textBlack)
        .padding(.init(all: 10), backgroundColor: UIColor.a3a5ba.withAlphaComponent(0.3), cornerRadius: 12)
        .onTap(self, action: #selector(buttonEditDidTouch))
    lazy var hideButton = UIImageView(width: 24, height: 24, image: .visibilityHide, tintColor: .textBlack)
        .padding(.init(all: 10), backgroundColor: UIColor.a3a5ba.withAlphaComponent(0.3), cornerRadius: 12)
        .onTap(self, action: #selector(buttonHideDidTouch))
    
    var editAction: CocoaAction?
    var hideAction: CocoaAction?
    
    override func commonInit() {
        super.commonInit()
        stackView.removeFromSuperview()
        
        let wrappedStackView = UIStackView(axis: .horizontal, spacing: 16, alignment: .center, arrangedSubviews: [
            stackView,
            buttonStackView
        ])
        
        addSubview(scrollView)
        scrollView.autoPinEdgesToSuperviewEdges()
        scrollView.addSubview(wrappedStackView)
        wrappedStackView.autoPinEdgesToSuperviewEdges()
        stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor).isActive = true
        
        buttonStackView.addArrangedSubviews([
            editButton,
            hideButton
        ])
    }
    
    override func setUp(with item: Wallet) {
        super.setUp(with: item)
        buttonStackView.isHidden = item.symbol == "SOL"
    }
    
    @objc func buttonEditDidTouch() {
        editAction?.execute()
    }
    
    @objc func buttonHideDidTouch() {
        hideAction?.execute()
    }
}

class MainWalletCell: EditableWalletCell {
    lazy var addressLabel = UILabel(text: "public key", textSize: 13, textColor: .textSecondary, numberOfLines: 1)
    lazy var indicatorColorView = UIView(width: 3, cornerRadius: 1.5)
    
    override var loadingViews: [UIView] {
        super.loadingViews + [addressLabel]
    }
    
    override func commonInit() {
        super.commonInit()        
        equityValueLabel.font = .boldSystemFont(ofSize: 15)
        equityValueLabel.setContentHuggingPriority(.required, for: .horizontal)
        tokenCountLabel.setContentHuggingPriority(.required, for: .horizontal)
        let vStackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
            row(arrangedSubviews: [coinNameLabel, equityValueLabel])
                .with(distribution: .fill),
            row(arrangedSubviews: [addressLabel, tokenCountLabel])
                .with(distribution: .fill)
        ])
        
        stackView.alignment = .center
        stackView.addArrangedSubviews([
            coinLogoImageView,
            vStackView,
            indicatorColorView
        ])
        
        indicatorColorView.heightAnchor.constraint(equalTo: coinLogoImageView.heightAnchor)
            .isActive = true
        
        coinNameLabel.textColor = .white
        equityValueLabel.textColor = .white
    }
    
    override func setUp(with item: Wallet) {
        super.setUp(with: item)
        if item.pubkey != nil {
            addressLabel.text = item.pubkeyShort()
        } else {
            addressLabel.text = nil
        }
        
        if item.amountInUSD == 0 {
            indicatorColorView.backgroundColor = .clear
        } else {
            indicatorColorView.backgroundColor = item.indicatorColor
        }
    }
    
    private func row(arrangedSubviews: [UIView]) -> UIStackView {
        let stackView = UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing)
        stackView.addArrangedSubviews(arrangedSubviews)
        return stackView
    }
}
