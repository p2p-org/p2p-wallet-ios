//
//  KeyboardDependingToolBar.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 26.10.2021.
//

import BEPureLayout

final class KeyboardDependingToolBar: TabBar {

    private let nextHandler: () -> Void
    private let pasteHandler: () -> Void

    private lazy var nextButton = WLButton(
        backgroundColor: .h5887ff,
        cornerRadius: 12,
        label: L10n.done,
        labelFont: .systemFont(ofSize: 15, weight: .semibold),
        textColor: .white,
        contentInsets: .init(x: 16, y: 10)
    )
        .onTap(self, action: #selector(buttonNextDidTouch))
    private lazy var pasteButton = WLButton(
        backgroundColor: UIColor.a3a5ba.withAlphaComponent(0.1),
        cornerRadius: 12,
        label: L10n.paste,
        labelFont: .systemFont(ofSize: 15, weight: .semibold),
        textColor: .white,
        contentInsets: .init(x: 16, y: 10)
    )
        .onTap(self, action: #selector(buttonPasteDidTouch))

    init(
        nextHandler: @escaping () -> Void,
        pasteHandler: @escaping () -> Void
    ) {
        self.nextHandler = nextHandler
        self.pasteHandler = pasteHandler

        super.init(cornerRadius: 20, contentInset: .init(x: 20, y: 10))

        backgroundColor = .h2f2f2f
        stackView.addArrangedSubviews(
            [
                pasteButton,
                UIView.spacer,
                nextButton
            ]
        )
    }

    func setConstraints() {
        autoPinEdge(toSuperviewEdge: .leading)
        autoPinEdge(toSuperviewEdge: .trailing)
        autoPinBottomToSuperViewAvoidKeyboard()
    }

    @objc
    private func buttonNextDidTouch() {
        nextHandler()
    }

    @objc
    private func buttonPasteDidTouch() {
        pasteHandler()
    }

}
