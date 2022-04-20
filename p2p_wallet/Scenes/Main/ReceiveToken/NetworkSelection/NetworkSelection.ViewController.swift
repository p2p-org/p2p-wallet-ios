//
//  NetworkSelection.ViewController.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 14.12.21.
//
//

import Down
import RxCocoa
import RxSwift
import UIKit

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
                            networkDescription: L10n
                                .receiveAnyTokenWithinTheSolanaNetworkEvenIfItIsNotIncludedInYourWalletList,
                            icon: .squircleSolanaIcon
                        ).setup { [unowned self] view in
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
                            networkDescription: L10n.ThisAddressAcceptsOnly
                                .youMayLoseAssetsBySendingAnotherCoin("Bitcoin"),
                            icon: .squircleBitcoinIcon
                        ).setup { [unowned self] view in
                            self.viewModel.tokenTypeDriver
                                .map { $0 == .btc }
                                .asDriver()
                                .drive(view.rx.isSelected)
                                .disposed(by: disposeBag)
                        }.onTap { [unowned self] in
                            viewModel.tapOnBitcoin()
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

        override func bind() {
            viewModel.showLoader
                .drive(onNext: { [weak self] show in
                    show ? self?.showIndetermineHud() : self?.hideHud()
                })
                .disposed(by: disposeBag)

            viewModel.toggleToBtc
                .drive(onNext: { [unowned self] in
                    viewModel.switchToken(.btc)
                    back()
                })
                .disposed(by: disposeBag)

            viewModel.showBitcoinConfirmation
                .drive(onNext: { [weak self] sceneType in
                    guard let self = self else { return }

                    let vc = BitcoinConfirmScene(
                        sceneType: sceneType,
                        viewModel: ReceiveToken.BitcoinConfirmScene.ViewModel(
                            receiveBitcoinViewModel: self.viewModel.receiveBitcoinViewModel
                        )
                    )

                    vc.rx.navigationAction
                        .bind(to: self.viewModel.renBtcAction)
                        .disposed(by: self.disposeBag)

                    self.present(vc, animated: true)
                })
                .disposed(by: disposeBag)

            viewModel.back
                .drive(onNext: { [weak self] in self?.back() })
                .disposed(by: disposeBag)

            viewModel.showAlert
                .drive(onNext: { [weak self] title, message in
                    self?.showAlert(title: title, message: message)
                })
                .disposed(by: disposeBag)
        }
    }
}
