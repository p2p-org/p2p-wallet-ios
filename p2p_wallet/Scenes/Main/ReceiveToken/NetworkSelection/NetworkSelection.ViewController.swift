//
//  NetworkSelection.ViewController.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 14.12.21.
//
//

import UIKit
import RxSwift
import RxCocoa

extension ReceiveToken {
    class NetworkSelectionScene: BEScene {
        @Injected private var viewModel: ReceiveSceneModel
        
        override var preferredNavigationBarStype: NavigationBarStyle { .hidden }
        
        override func build() -> UIView {
            BESafeArea {
                UIStackView(axis: .vertical, alignment: .fill) {
                    WLNavigationBar(forAutoLayout: ()).setup { view in
                        guard let navigationBar = view as? WLNavigationBar else { return }
                        navigationBar.backgroundColor = .clear
                        navigationBar.titleLabel.text = L10n.chooseTheNetwork
                        navigationBar.backButton.onTap { [unowned self] in self.back() }
                    }
                    UIView.defaultSeparator()
                    
                    BEScrollView(contentInsets: .init(all: 18)) {
                        // Solana network
                        NetworkCell(
                            networkName: "Solana",
                            networkDescription: L10n.receiveAnyTokenWithinTheSolanaNetworkEvenIfItIsNotIncludedInYourWalletList,
                            icon: .squircleSolanaIcon
                        ).setup { [unowned self] view in
                            let view = view as! NetworkCell
                            self.viewModel.tokenTypeDriver
                                .map { type -> Bool in type == .solana }
                                .asDriver()
                                .drive(view.rx.isSelected)
                                .disposed(by: disposeBag)
                        }.onTap { [unowned self] in
                            self.viewModel.switchToken(.solana)
                            self.back()
                        }
                        
                        UIView.defaultSeparator().padding(.init(x: 0, y: 25))
                        
                        // Bitcoin network
                        NetworkCell(
                            networkName: "Bitcoin",
                            networkDescription: L10n.ThisAddressAccepts.youMayLoseAssetsBySendingAnotherCoin("Bitcoin"),
                            icon: .squircleBitcoinIcon
                        ).setup { [unowned self] view in
                            let view = view as! NetworkCell
                            self.viewModel.tokenTypeDriver
                                .map { type -> Bool in type == .btc }
                                .asDriver()
                                .drive(view.rx.isSelected)
                                .disposed(by: disposeBag)
                        }.onTap { [unowned self] in
                            Driver.combineLatest(
                                self.viewModel.receiveBitcoinViewModel.isReceivingRenBTCDriver,
                                self.viewModel.receiveBitcoinViewModel.conditionAcceptedDriver
                            ).drive { [weak self] (isRenBTCCreated, conditionalAccepted) in
                                if isRenBTCCreated && conditionalAccepted {
                                    self?.viewModel.switchToken(.btc)
                                    self?.back()
                                } else {
                                    let vc = BitcoinConfirmScene { [weak self] in
                                        self?.viewModel.receiveBitcoinViewModel.acceptConditionAndLoadAddress()
                                        self?.viewModel.switchToken(.btc)
                                        self?.back()
                                    }
                                    self?.present(vc, animated: true)
                                }
                            }.disposed(by: disposeBag)
                            
                        }
                        
                        // Description
                        UIStackView(axis: .vertical, spacing: 12, alignment: .leading) {
                            UILabel(text: "Solana", textSize: 17, weight: .semibold)
                            UILabel(
                                text: L10n
                                    .TheSolanaProgramLibrarySPLIsACollectionOfOnChainProgramsMaintainedByTheSolanaTeam
                                    .TheSPLTokenProgramIsTheTokenStandardOfTheSolanaBlockchain
                                    .SimilarToERC20TokensOnTheEthereumNetworkSPLTokensAreDesignedForDeFiApplications
                                    .splTokensCanBeTradedOnSerumASolanaBasedDecentralizedExchangeAndFTX,
                                numberOfLines: 0
                            )
                            
                            UILabel(text: "Bitcoin", textSize: 17, weight: .semibold)
                            UILabel(
                                text: L10n
                                    .WhenYouChooseTheBitcoinNetworkYourAddressAcceptsOnlyBitcoin
                                    .YouMayLoseAssetsBySendingAnotherCoin
                                    ._0
                                    ._000112BTCIsTheMinimumTransactionAmountAndYouHave36HoursToCompleteTheTransactionAfterReceivingTheAddress,
                                numberOfLines: 0
                            )
                        }.padding(.init(x: 18, y: 18), backgroundColor: .fafafc)
                            .padding(.init(only: .top, inset: 35))
                    }
                }
            }
        }
    }
    
    fileprivate class NetworkCell: BECompositionView {
        let networkName: String
        let networkDescription: String
        let icon: UIImage
        var isSelected: Bool {
            didSet {
                selectionView.hidden(!isSelected)
            }
        }
        
        // Refs
        var selectionView: UIView!
        
        init(networkName: String, networkDescription: String, icon: UIImage, isSelected: Bool = false) {
            self.networkName = networkName
            self.networkDescription = networkDescription
            self.icon = icon
            self.isSelected = isSelected
            super.init()
        }
        
        override func build() -> UIView {
            UIStackView(axis: .horizontal, alignment: .top) {
                UIImageView(width: 44, height: 44, image: icon)
                UIStackView(axis: .vertical, alignment: .leading) {
                    UILabel(text: L10n.network(networkName), textSize: 17, weight: .semibold)
                    UILabel(
                        text: networkDescription,
                        textColor: .secondaryLabel,
                        numberOfLines: 3
                    )
                }.padding(.init(only: .left, inset: 12))
                UIImageView(width: 22, height: 22, image: .checkBoxIOS)
                    .setup { view in self.selectionView = view }
            }
        }
    }
}

extension Reactive where Base: ReceiveToken.NetworkCell {
    /// Bindable sink for `text` property.
    fileprivate var isSelected: Binder<Bool> {
        Binder(base) { view, value in
            view.isSelected = value
        }
    }
}
