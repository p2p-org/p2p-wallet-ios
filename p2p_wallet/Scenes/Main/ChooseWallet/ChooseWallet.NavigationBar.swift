//
//  ChooseWallet.NavigationBar.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 14.12.2021.
//

import UIKit
import BEPureLayout

extension ChooseWallet {
    final class NavigationBar: BEView {
        private let navigationBar = WLNavigationBar()

        private let closeHandler: () -> Void

        init(
            title: String?,
            closeHandler: @escaping () -> Void
        ) {
            self.closeHandler = closeHandler

            super.init(frame: .zero)

            configureSelf()
            configureNavigationBar(title: title)
        }

        private func configureSelf() {
            backgroundColor = .fafafc
            addSubview(navigationBar)
            navigationBar.autoPinEdgesToSuperviewSafeArea(with: .init(only: .top, inset: 14))
        }

        private func configureNavigationBar(title: String?) {
            navigationBar.backButton.isHidden = true
            navigationBar.backgroundColor = .fafafc
            navigationBar.titleLabel.text = title
            let closeButton = UIButton(
                label: L10n.close,
                labelFont: .systemFont(ofSize: 17, weight: .bold),
                textColor: .h5887ff
            )
            closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
            navigationBar.rightItems.addArrangedSubview(closeButton)
        }

        @objc
        func close() {
            closeHandler()
        }
    }
}
