//
//  SendToken.ChooseRecipientAndNetwork.AddressViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 29/11/2021.
//

import Foundation
import UIKit

extension SendToken.ChooseRecipientAndNetwork {
    final class AddressViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Dependencies
        private let viewModel: SendTokenChooseRecipientAndNetworkViewModelType
        
        // MARK: - Initializer
        init(viewModel: SendTokenChooseRecipientAndNetworkViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
        override func setUp() {
            super.setUp()
            let label = UILabel(text: "address")
            view.addSubview(label)
            label.autoCenterInSuperview()
        }
    }
}
