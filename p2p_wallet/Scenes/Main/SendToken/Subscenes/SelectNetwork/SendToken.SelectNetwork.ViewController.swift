//
//  SendToken.SelectNetwork.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/12/2021.
//

import Foundation
import RxCocoa

extension SendToken.SelectNetwork {
    final class ViewController: BEScene {
        override var preferredNavigationBarStype: NavigationBarStyle { .hidden }
        
        private let viewModel: SendTokenSelectNetworkViewModelType
        
        // Internal state
        private let selectedNetwork: BehaviorRelay<SendToken.Network>
        
        init(viewModel: SendTokenSelectNetworkViewModelType) {
            self.viewModel = viewModel
            self.selectedNetwork = BehaviorRelay(value: viewModel.getSelectedNetwork())
            super.init()
        }
        
        override func build() -> UIView {
            UIStackView(axis: .vertical, alignment: .fill) {
                NewWLNavigationBar(initialTitle: L10n.chooseTheNetwork, separatorEnable: false)
                    .onBack { [unowned self] in self.back() }
                
                BEScrollView(contentInsets: .init(x: 18, y: 4)) {
                    // Description
                    UIView.greyBannerView {
                        UILabel(
                            text: L10n
                                .P2PWalletWillAutomaticallyMatchYourWithdrawalTargetAddressToTheCorrectNetworkForMostWithdrawals
                                .howeverBeforeSendingYourFundsMakeSureToDoubleCheckTheSelectedNetwork,
                            textSize: 15,
                            numberOfLines: 0)
                    }.padding(.init(only: .bottom, inset: 35))
                    
                    // Solana cell
                    if viewModel.getSelectableNetworks().contains(.solana) {
                        _NetworkView()
                            .setUp(network: .solana, prices: viewModel.getSOLAndRenBTCPrices())
                            .setupWithType(_NetworkView.self) { view in
                                selectedNetwork.asDriver()
                                    .map { network in network != .solana }
                                    .drive(view.tickView.rx.isHidden)
                                    .disposed(by: disposeBag)
                            }
                            .onTap { [unowned self] in self.switchNetwork(to: .solana) }
                        
                        UIView.greenBannerView(contentInset: .init(x: 12, y: 8)) {
                            UILabel(
                                text: L10n
                                    .OnTheSolanaNetworkTheFirst100TransactionsInADayArePaidByP2P
                                    .Org
                                    .subsequentTransactionsWillBeChargedBasedOnTheSolanaBlockchainGasFee,
                                textColor: .h34c759,
                                numberOfLines: 5
                            )
                        }.padding(.init(only: .top, inset: 18))
                    }
                    
                    // Bitcoin cell
                    if viewModel.getSelectableNetworks().contains(.bitcoin) {
                        UIView.defaultSeparator().padding(.init(top: 16, left: 0, bottom: 25, right: 0))
                        _NetworkView()
                            .setUp(network: .bitcoin, prices: viewModel.getSOLAndRenBTCPrices())
                            .setupWithType(_NetworkView.self) { view in
                                selectedNetwork.asDriver()
                                    .map { network in network != .bitcoin }
                                    .drive(view.tickView.rx.isHidden)
                                    .disposed(by: disposeBag)
                            }
                            .onTap { [unowned self] in self.switchNetwork(to: .bitcoin) }
                    }
                    
                }
            }
        }
        
        private func switchNetwork(to network: SendToken.Network) {
            let networkName = viewModel.getSelectedNetwork().rawValue.uppercaseFirst
            
            showAlert(
                title: L10n.changeTheNetwork,
                message: L10n.ifTheNetworkIsChangedToTheAddressFieldMustBeFilledInWithA(networkName, L10n.compatibleAddress(networkName)),
                buttonTitles: [L10n.discard, L10n.change],
                highlightedButtonIndex: 1,
                destroingIndex: 0
            ) { [weak self] index in
                if index == 0 {
                    self?.back()
                } else {
                    self?.selectedNetwork.accept(network)
                    self?.viewModel.selectNetwork(network)
                    self?.viewModel.navigateToChooseRecipientAndNetworkWithPreSelectedNetwork(network)
                }
            }
        }
    }
    
    private class _NetworkView: SendToken.NetworkView {
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
