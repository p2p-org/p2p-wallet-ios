//
//  SwapTokenSettings.NavigationBar.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 21.12.2021.
//

extension SwapTokenSettings {
    final class NavigationBar: WLNavigationBar {
        private let backHandler: () -> Void

        init(backHandler: @escaping () -> Void) {
            self.backHandler = backHandler

            super.init(frame: .zero)

            configureSelf()
        }

        private func configureSelf() {
            backButton.onTap(self, action: #selector(back))
            titleLabel.text = L10n.swapSettings
        }

        @objc
        func back() {
            backHandler()
        }
    }
}
