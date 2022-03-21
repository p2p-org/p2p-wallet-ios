//
//  WLSectionHeaderView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/03/2021.
//

import Foundation

class WLSectionHeaderView: UICollectionReusableView {
    lazy var stackView = UIStackView(axis: .vertical, spacing: 16, alignment: .fill, distribution: .fill)

    lazy var headerLabel = UILabel(textSize: 17, weight: .bold, numberOfLines: 0)

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
        stackView.addArrangedSubview(headerLabel)
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

    func removeStackView(completion: (() -> Void)? = nil) {
        if stackView.superview != nil {
            stackView.removeFromSuperview()
            setNeedsLayout()
            completion?()
        }
    }

    func setUp(
        headerTitle: String,
        headerFont: UIFont = .systemFont(ofSize: 17, weight: .bold),
        headerColor: UIColor? = nil
    ) {
        headerLabel.text = headerTitle
        headerLabel.font = headerFont
        if let color = headerColor {
            headerLabel.textColor = color
        }
    }
}
