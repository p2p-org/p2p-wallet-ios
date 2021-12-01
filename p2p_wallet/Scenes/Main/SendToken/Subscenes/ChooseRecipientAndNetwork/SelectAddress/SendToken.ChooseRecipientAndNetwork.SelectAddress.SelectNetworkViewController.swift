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
        
        // MARK: - Subviews
        private lazy var networkViews: [NetworkView] = {
            var networkViews = viewModel.getSelectableNetwork()
                .map {network -> NetworkView in
                    let view = NetworkView(viewModel: viewModel)
                    view.setUp(network: network, fee: network.defaultFee)
                    return view
                }
            
            return networkViews
        }()
        
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
            rootView.stackView.spacing = 0
            rootView.stackView.addArrangedSubviews {
                UIView.greyBannerView {
                    UILabel(text: L10n.P2PWaletWillAutomaticallyMatchYourWithdrawalTargetAddressToTheCorrectNetworkForMostWithdrawals.howeverBeforeSendingYourFundsMakeSureToDoubleCheckTheSelectedNetwork, textSize: 15, numberOfLines: 0)
                }
                
                BEStackViewSpacing(10)
            }
            
            // networks
            rootView.stackView.addArrangedSubviews(
                networkViews.map {$0.padding(.init(x: 0, y: 26))}
            )
        }
    }
}
