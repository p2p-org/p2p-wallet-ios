//
//  WellDoneVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation
import SwiftUI

class WellDoneVC: WLIntroVC {
    let viewModel: Root.ViewModel
    let analyticsManager: AnalyticsManagerType
    init(viewModel: Root.ViewModel, analyticsManager: AnalyticsManagerType) {
        self.viewModel = viewModel
        self.analyticsManager = analyticsManager
        super.init()
    }
    
    lazy var acceptButton = WLButton.stepButton(type: .blue, label: nil)
        .onTap(self, action: #selector(finishSetup))
    
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
