//
//  ReserveName.NavigationBar.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 27.11.2021.
//

extension ReserveName {
    final class NavigationBar: WLNavigationBar {
        private let backHandler: () -> Void
        private let skipHandler: () -> Void

        init(
            canSkip: Bool,
            backHandler: @escaping () -> Void,
            skipHandler: @escaping () -> Void
        ) {
            self.backHandler = backHandler
            self.skipHandler = skipHandler

            super.init(frame: .zero)

            configureSelf(canSkip: canSkip)
        }

        private func configureSelf(canSkip: Bool) {
            backButton.onTap(self, action: #selector(back))
            titleLabel.text = L10n.reserveP2PUsername

            if canSkip {
                let skipButton = UIButton(label: L10n.skip.capitalized, textColor: .h5887ff)
                skipButton.addTarget(self, action: #selector(skip), for: .touchUpInside)
                rightItems.addArrangedSubview(skipButton)
            }
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
