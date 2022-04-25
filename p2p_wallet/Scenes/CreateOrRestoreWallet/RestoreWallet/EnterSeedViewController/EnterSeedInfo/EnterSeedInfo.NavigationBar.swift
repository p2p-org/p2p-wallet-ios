//
//  EnterSeedInfoNavigationBar.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 18.11.2021.
//

import UIKit

extension EnterSeedInfo {
    final class NavigationBar: WLNavigationBar {
        private let doneHandler: () -> Void

        init(doneHandler: @escaping () -> Void) {
            self.doneHandler = doneHandler

            super.init(frame: .zero)
            leftItems.arrangedSubviews.forEach { $0.removeFromSuperview() }

            configureSelf()
        }

        private func configureSelf() {
            titleLabel.text = L10n.whatIsASecurityKey
            let infoButton = UIButton(
                label: L10n.done,
                labelFont: .systemFont(ofSize: 17, weight: .bold),
                textColor: .h5887ff
            )
            infoButton.addTarget(self, action: #selector(done), for: .touchUpInside)
            rightItems.addArrangedSubview(infoButton)
            backgroundColor = .clear
            // Navigation separator
            let separator = UIView.defaultSeparator(height: 0.5)
            separator.backgroundColor = .black.withAlphaComponent(0.3)
            addSubview(separator)
            separator.autoPinEdge(toSuperviewEdge: .leading)
            separator.autoPinEdge(toSuperviewEdge: .trailing)
            separator.autoPinEdge(toSuperviewEdge: .bottom)
        }

        @objc
        func done() {
            doneHandler()
        }
    }
}
