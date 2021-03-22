//
//  WellDoneVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation
import SwiftUI

class WellDoneVC: WLIntroVC {
    let viewModel: RootViewModel
    init(viewModel: RootViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    lazy var acceptButton = WLButton.stepButton(type: .blue, label: nil)
        .onTap(viewModel, action: #selector(RootViewModel.navigateToMain))
    
    override func setUp() {
        super.setUp()
        titleLabel.text = L10n.wellDone
        descriptionLabel.text = L10n.exploreP2PWalletAndDepositFundsWhenYouReReady
        
        stackView.addArrangedSubviews([acceptButton, UIView(height: 56)])
        acceptButton.setTitle(L10n.finishSetup, for: .normal)
    }
}
