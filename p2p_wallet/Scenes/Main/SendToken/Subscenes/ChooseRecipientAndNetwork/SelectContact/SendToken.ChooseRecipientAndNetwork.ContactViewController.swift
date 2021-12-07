//
//  SendToken.ChooseRecipientAndNetwork.ContactViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 29/11/2021.
//

import Foundation

extension SendToken.ChooseRecipientAndNetwork {
    final class ContactViewController: BaseVC {
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
            let label = UILabel(text: "contact")
            view.addSubview(label)
            label.autoCenterInSuperview()
        }
    }
}
