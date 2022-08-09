//
//  ShowHideButton.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 20.01.2022.
//

import PureLayout
import UIKit

final class ShowHideButton: UIButton {
    private let textLabel = UILabel(textSize: 15, weight: .regular)
    private let arrowView = UIImageView(width: 16, height: 16, tintColor: .textBlack)

    private let closedText: String
    private let openedText: String

    var isOpened: Bool = false {
        didSet {
            setState(isShown: isShown)
        }
    }

    init(closedText: String, openedText: String) {
        self.closedText = closedText
        self.openedText = openedText

        super.init(frame: .zero)

        layout()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func setState(isShown: Bool) {
        textLabel.text = isShown ? openedText : closedText
        arrowView.image = isShown ? .chevronUp : .chevronDown
    }

    private func layout() {
        let stackView = UIStackView(axis: .horizontal, spacing: 4) {
            textLabel
            arrowView
        }

        stackView.isUserInteractionEnabled = false

        addSubview(stackView)

        stackView.autoAlignAxis(toSuperviewAxis: .vertical)
        stackView.autoAlignAxis(toSuperviewAxis: .horizontal)
    }
}
