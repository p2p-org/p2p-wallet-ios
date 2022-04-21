//
//  SectionHeaderView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/3/20.
//

import Foundation

class SectionHeaderView: UICollectionReusableView {
    lazy var stackView = UIStackView(axis: .vertical, spacing: 16, alignment: .fill, distribution: .fill)

    lazy var headerLabel = UILabel(
        text: "Wallets",
        textSize: 12,
        weight: .medium,
        textColor: .secondaryLabel,
        numberOfLines: 0
    )

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    @available(*, unavailable,
               message: "Loading this view from a nib is unsupported in favor of initializer dependency injection.")
    public required init?(coder _: NSCoder) {
        fatalError(
            "Loading this view controller from a nib is unsupported in favor of initializer dependency injection."
        )
    }

    func commonInit() {
        addStackView()
        stackView.addArrangedSubview(headerLabel.padding(.init(x: .defaultPadding, y: 0)))
    }

    func addStackView(completion: (() -> Void)? = nil) {
        if stackView.superview == nil {
            addSubview(stackView)
            stackView.autoPinEdge(toSuperviewEdge: .top, withInset: 16)
            stackView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 16)
            stackView.autoPinEdge(toSuperviewEdge: .leading)
            stackView.autoPinEdge(toSuperviewEdge: .trailing)
            setNeedsLayout()
            completion?()
        }
    }

    func setUp(
        headerTitle: String,
        headerFont: UIFont = .systemFont(ofSize: 12, weight: .medium),
        textColor: UIColor = .secondaryLabel
    ) {
        headerLabel.text = headerTitle
        headerLabel.font = headerFont
        headerLabel.textColor = textColor
    }
}
