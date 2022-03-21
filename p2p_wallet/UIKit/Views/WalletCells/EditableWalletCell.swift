//
//  EditableWalletCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/03/2021.
//

import Action
import Foundation

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
    lazy var hideButton = UIImageView(width: 24, height: 24, image: .visibilityHide, tintColor: .textBlack)

    var editAction: CocoaAction?
    var hideAction: CocoaAction?

    override func commonInit() {
        super.commonInit()
        stackView.removeFromSuperview()

        let wrappedStackView = UIStackView(axis: .horizontal, spacing: 16, alignment: .center, arrangedSubviews: [
            stackView,
            buttonStackView,
        ])

        addSubview(scrollView)
        scrollView.autoPinEdgesToSuperviewEdges()
        scrollView.addSubview(wrappedStackView)
        wrappedStackView.autoPinEdgesToSuperviewEdges()
        stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor).isActive = true

        buttonStackView.addArrangedSubviews([
            //            editButton
//                .padding(.init(all: 10), backgroundColor: UIColor.a3a5ba.withAlphaComponent(0.3), cornerRadius: 12)
//                .onTap(self, action: #selector(buttonEditDidTouch)),
            hideButton
                .padding(.init(all: 10), backgroundColor: UIColor.a3a5ba.withAlphaComponent(0.3), cornerRadius: 12)
                .onTap(self, action: #selector(buttonHideDidTouch)),
        ])
    }

    override func setUp(with item: Wallet) {
        super.setUp(with: item)
        buttonStackView.isHidden = item.isNativeSOL
        hideButton.image = item.isHidden ? .visibilityShow : .visibilityHide
        stackView.alpha = item.isHidden ? 0.5 : 1
    }

    @objc func buttonEditDidTouch() {
        editAction?.execute()
    }

    @objc func buttonHideDidTouch() {
        hideAction?.execute()
    }
}
