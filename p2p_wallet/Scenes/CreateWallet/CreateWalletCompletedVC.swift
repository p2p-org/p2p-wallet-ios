//
//  CreateWalletCompletedVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
import SwiftUI

class CreateWalletCompletedVC: WLIntroVC {
    // MARK: - Subviews
    lazy var nextButton = WLButton.stepButton(type: .blue, label: L10n.next.uppercaseFirst)
        .onTap(self, action: #selector(buttonNextDidTouch))
    
    // MARK: - Methods
    let rootViewModel: RootViewModel
    init(rootViewModel: RootViewModel) {
        self.rootViewModel = rootViewModel
        super.init()
    }
    
    override func setUp() {
        super.setUp()
        descriptionLabel.isHidden = false
        titleLabel.text = L10n.congratulations
        descriptionLabel.text = L10n.yourWalletHasBeenSuccessfullyCreated
        
        buttonsStackView.addArrangedSubviews([
            nextButton,
            UIView(height: 56)
        ])
    }
    
    // MARK: - Actions
    @objc func buttonNextDidTouch() {
        rootViewModel.navigationSubject.accept(.settings(.pincode))
    }
}
