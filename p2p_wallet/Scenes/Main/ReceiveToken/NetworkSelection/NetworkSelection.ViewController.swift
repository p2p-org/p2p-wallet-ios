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
import Down

extension ReceiveToken {
    class NetworkSelectionScene: BEScene {
        override var preferredNavigationBarStype: NavigationBarStyle { .hidden }
        
        private let viewModel: ReceiveSceneModel
        
        init(viewModel: ReceiveSceneModel) {
            self.viewModel = viewModel
            super.init()
        }
        
        override func build() -> UIView {
            BESafeArea {
                UIStackView(axis: .vertical, alignment: .fill) {
                    NewWLNavigationBar(initialTitle: L10n.chooseTheNetwork, separatorEnable: false)
                        .onBack { [unowned self] in self.back() }
                    
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
                            networkDescription: L10n.ThisAddressAcceptsOnly.youMayLoseAssetsBySendingAnotherCoin("Bitcoin"),
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
                        UIView.greyBannerView(spacing: 12, alignment: .fill) {
                            UILabel(text: "Solana", textSize: 17, weight: .semibold)
                            UILabel(
                                text: L10n
                                    .TheSolanaProgramLibrarySPLIsACollectionOfOnChainProgramsMaintainedByTheSolanaTeam
                                    .TheSPLTokenProgramIsTheTokenStandardOfTheSolanaBlockchain
                                    .similarToERC20TokensOnTheEthereumNetworkSPLTokensAreDesignedForDeFiApplications,
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
                        }.padding(.init(only: .top, inset: 35))
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
                UIStackView(axis: .vertical, spacing: 4, alignment: .leading) {
                    UILabel(text: L10n.network(networkName).onlyUppercaseFirst(), textSize: 17, weight: .semibold)
                    UILabel(
                        textColor: .secondaryLabel,
                        numberOfLines: 3
                    ).setAttributeString(networkDescription.asMarkdown(
                        textColor: .secondaryLabel
                    ))
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
