//
//  CreateOrRestoreReserveName.NavigationBar.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 27.11.2021.
//

extension CreateOrRestoreReserveName {
    final class NavigationBar: WLNavigationBar {
        private let backHandler: () -> Void
        private let skipHandler: () -> Void

        init(
            backHandler: @escaping () -> Void,
            skipHandler: @escaping () -> Void
        ) {
            self.backHandler = backHandler
            self.skipHandler = skipHandler

            super.init(frame: .zero)

            configureSelf()
        }

        private func configureSelf() {
            backButton.onTap(self, action: #selector(back))
            titleLabel.text = L10n.enterYourSecurityKey

            let skipButton = UIButton(label: L10n.skip.capitalized, textColor: .h5887ff)
            skipButton.addTarget(self, action: #selector(skip), for: .touchUpInside)
            rightItems.addArrangedSubview(skipButton)
        }

        @objc
        func back() {
            backHandler()
        }

        @objc
        func skip() {
            skipHandler()
        }
    }
}
