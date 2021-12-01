//
//  SendToken.ChooseRecipientAndNetwork.SelectAddress.SelectNetworkViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 01/12/2021.
//

import Foundation
import BEPureLayout

extension SendToken.ChooseRecipientAndNetwork.SelectAddress {
    final class SelectNetworkViewController: SendToken.BaseViewController {
        // MARK: - Dependencies
        private let viewModel: SendTokenChooseRecipientAndNetworkSelectAddressViewModelType
        
        // MARK: - Initializer
        init(viewModel: SendTokenChooseRecipientAndNetworkSelectAddressViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            // navigation bar
            navigationBar.titleLabel.text = L10n.chooseTheNetwork
            
            // container
            let rootView = ScrollableVStackRootView()
            view.addSubview(rootView)
            rootView.autoPinEdge(.top, to: .bottom, of: navigationBar)
            rootView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
            
            rootView.stackView.addArrangedSubviews {
                UIView.greyBannerView {
                    UILabel(text: L10n.P2PWaletWillAutomaticallyMatchYourWithdrawalTargetAddressToTheCorrectNetworkForMostWithdrawals.howeverBeforeSendingYourFundsMakeSureToDoubleCheckTheSelectedNetwork, textSize: 15, numberOfLines: 0)
                }
                
                BEStackViewSpacing(35)
            }
            
            // networks
            let selectableNetworks = viewModel.getSelectableNetwork()
//            for network in selectableNetworks {
//                let view = SendToken.ChooseRecipientAndNetwork.SelectAddress.NetworkView()
//                view.setUp(network: <#T##SendToken.Network#>, fee: <#T##SendToken.Fee#>)
//            }
        }
    }
}
