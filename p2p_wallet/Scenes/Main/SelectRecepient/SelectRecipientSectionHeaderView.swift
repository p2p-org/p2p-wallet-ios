//
//  SelectRecipientSectionHeaderView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 26.10.2021.
//

import UIKit

final class SelectRecipientSectionHeaderView: UITableViewHeaderFooterView {
    private let titleLabel = UILabel(textSize: 15, weight: .medium, textColor: .a3a5ba)

    static let identifier = "SelectRecipientSectionHeaderView"

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        addSubviews()
        setConstraints()
        textLabel?.isHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTitle(_ title: String?) {
        titleLabel.text = title
    }

    private func addSubviews() {
        [titleLabel].forEach(addSubview)
    }

    private func setConstraints() {
        let constraints = [
            titleLabel.autoAlignAxis(toSuperviewAxis: .horizontal),
            titleLabel.autoPinEdge(toSuperviewEdge: .leading, withInset: 20),
            titleLabel.autoPinEdge(toSuperviewEdge: .trailing, withInset: 20)
        ]

        NSLayoutConstraint.activate(constraints)
    }

}
