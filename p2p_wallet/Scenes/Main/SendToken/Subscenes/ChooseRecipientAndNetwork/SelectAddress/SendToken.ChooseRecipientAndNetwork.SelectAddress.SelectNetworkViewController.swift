//
//  SendToken.ChooseRecipientAndNetwork.SelectAddress.SelectNetworkViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 01/12/2021.
//

import Foundation
import BEPureLayout
import UIKit

extension SendToken.ChooseRecipientAndNetwork.SelectAddress {
    final class SelectNetworkViewController: SendToken.BaseViewController {
        // MARK: - Dependencies
        private let viewModel: SendTokenChooseRecipientAndNetworkSelectAddressViewModelType
        
        // MARK: - Subviews
        private lazy var networkViews: [_NetworkView] = {
            var networkViews = viewModel.getSelectableNetwork()
                .map {network -> _NetworkView in
                    let view = _NetworkView()
                    view.network = network
                    view.setUp(network: network, fee: network.defaultFee, renBTCPrice: viewModel.getRenBTCPrice())
                    if network == .solana {
                        view.addArrangedSubview(
                            UILabel(text: L10n.paidByP2p, textSize: 13, textColor: .h34c759)
                                .withContentHuggingPriority(.required, for: .horizontal)
                                .padding(.init(x: 12, y: 8), backgroundColor: .f5fcf7, cornerRadius: 12)
                                .border(width: 1, color: .h34c759)
                                .withContentHuggingPriority(.required, for: .horizontal)
                        )
                    }
                    return view.onTap(self, action: #selector(networkViewDidTouch(_:)))
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
            for (index, view) in networkViews.enumerated() {
                rootView.stackView.addArrangedSubview(view.padding(.init(x: 0, y: 26)))
                if index < networkViews.count - 1 {
                    rootView.stackView.addArrangedSubview(.separator(height: 1, color: .separator))
                }
            }
        }
        
        override func bind() {
            super.bind()
            viewModel.networkDriver
                .drive(onNext: {[weak self] network in
                    guard let self = self else {return}
                    for view in self.networkViews {
                        view.tickView.alpha = view.network == network ? 1: 0
                    }
                })
                .disposed(by: disposeBag)
        }
        
        @objc private func networkViewDidTouch(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view as? _NetworkView, let network = view.network else {
                return
            }
            viewModel.selectNetwork(network)
        }
    }
    
    private class _NetworkView: NetworkView {
        fileprivate var network: SendToken.Network?
        fileprivate lazy var tickView = UIImageView(width: 14.3, height: 14.19, image: .tick, tintColor: .h5887ff)
        override init() {
            super.init()
            addArrangedSubview(tickView)
        }
        
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
