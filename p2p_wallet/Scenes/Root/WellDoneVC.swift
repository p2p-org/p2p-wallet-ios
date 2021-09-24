//
//  WellDoneVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation
import SwiftUI

class WellDoneVC: WLIntroVC {
    // MARK: - Dependencies
    @Injected private var viewModel: RootViewModelType
    @Injected private var analyticsManager: AnalyticsManagerType
    
    // MARK: - Subviews
    lazy var acceptButton = WLButton.stepButton(type: .blue, label: nil)
        .onTap(self, action: #selector(finishSetup))
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        analyticsManager.log(event: .setupFinishOpen)
    }
    
    override func setUp() {
        super.setUp()
        titleLabel.text = L10n.wellDone
        descriptionLabel.text = L10n.exploreP2PWalletAndDepositFundsWhenYouReReady
        
        stackView.addArrangedSubviews([acceptButton, UIView(height: 56)])
        acceptButton.setTitle(L10n.finishSetup, for: .normal)
    }
    
    @objc func finishSetup() {
        analyticsManager.log(event: .setupFinishClick)
        viewModel.finishSetup()
    }
}
