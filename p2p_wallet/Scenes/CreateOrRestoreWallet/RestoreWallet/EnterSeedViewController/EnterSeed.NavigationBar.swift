//
//  EnterSeedNavigationBar.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 11.11.2021.
//

import UIKit

extension EnterSeed {
    final class NavigationBar: WLNavigationBar {
        private let backHandler: () -> Void
        
        init(backHandler: @escaping () -> Void) {
            self.backHandler = backHandler
            
            super.init(frame: .zero)
            
            configureSelf()
        }
        
        private func configureSelf() {
            backButton.onTap(self, action: #selector(back))
            titleLabel.text = L10n.enterYourSecurityKey
        }
        
        @objc
        func back() {
            backHandler()
        }
    }
}
