//
//  NewOrcaSwap.NavigationBar.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 30.11.2021.
//

import UIKit

extension OrcaSwapV2 {
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
            rightItems.addArrangedSubview(
                UIImageView(width: 24, height: 24, image: .settings, tintColor: .h5887ff)
                    .onTap(self, action: #selector(settings))
            )
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
