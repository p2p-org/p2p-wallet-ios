//
//  NewOrcaSwap.NavigationBar.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 30.11.2021.
//

import UIKit

extension NewOrcaSwap {
    final class NavigationBar: WLNavigationBar {
        private let backHandler: () -> Void
        private let settingsHandler: () -> Void

        init(
            backHandler: @escaping () -> Void,
            settingsHandler: @escaping () -> Void
        ) {
            self.backHandler = backHandler
            self.settingsHandler = settingsHandler

            super.init(frame: .zero)

            configureSelf()
        }

        private func configureSelf() {
            backButton.onTap(self, action: #selector(back))
            titleLabel.text = L10n.swap
            let settingsButton = UIButton(width: 24, height: 24)
            settingsButton.setImage(.settings, for: .normal)
            settingsButton.addTarget(self, action: #selector(settings), for: .touchUpInside)
            rightItems.addArrangedSubview(settingsButton)
        }

        @objc
        func back() {
            backHandler()
        }

        @objc
        func settings() {
            settingsHandler()
        }
    }
}
