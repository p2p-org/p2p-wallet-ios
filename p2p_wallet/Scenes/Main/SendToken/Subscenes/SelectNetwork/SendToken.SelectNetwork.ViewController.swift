//
//  SendToken.SelectNetwork.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/12/2021.
//

import Foundation
import RxCocoa

extension SendToken.SelectNetwork {
    final class ViewController: BaseViewController {
        private let viewModel: SendTokenSelectNetworkViewModelType

        // Internal state
        private let selectedNetwork: BehaviorRelay<SendToken.Network>

        init(viewModel: SendTokenSelectNetworkViewModelType) {
            self.viewModel = viewModel
            selectedNetwork = BehaviorRelay(value: viewModel.getSelectedNetwork())
            super.init()
            navigationItem.title = L10n.chooseTheNetwork
        }

        override func build() -> UIView {
            UIStackView(axis: .vertical, alignment: .fill) {
                BEScrollView(contentInsets: .init(x: 18, y: 4)) {
                    // Description
                    UIView.greyBannerView {
                        UILabel(
                            text: L10n
                                .KeyAppWillAutomaticallyMatchYourWithdrawalTargetAddressToTheCorrectNetworkForMostWithdrawals
                                .howeverBeforeSendingYourFundsMakeSureToDoubleCheckTheSelectedNetwork,
                            textSize: 15,
                            numberOfLines: 0
                        )
                    }.padding(.init(only: .bottom, inset: 35))

                    // Solana cell
                    if viewModel.getSelectableNetworks().contains(.solana) {
                        createNetworkView(network: .solana)
                        UIView.greenBannerView(contentInset: .init(x: 12, y: 8)) {
                            UILabel(
                                text: nil,
                                textColor: .h34c759,
                                numberOfLines: 5
                            )
                                .setup { label in
                                    viewModel.getFreeTransactionFeeLimit()
                                        .map(\.maxUsage)
                                        .subscribe(onSuccess: { [weak label] maxUsage in
                                            label?.text = L10n.OnTheSolanaNetworkTheFirstTransactionsInADayArePaidByKeyApp
                                                .subsequentTransactionsWillBeChargedBasedOnTheSolanaBlockchainGasFee(
                                                    maxUsage
                                                )
                                        })
                                        .disposed(by: disposeBag)
                                }
                        }.padding(.init(only: .top, inset: 18))
                    }

                    // Bitcoin cell
                    if viewModel.getSelectableNetworks().contains(.bitcoin) {
                        UIView.defaultSeparator().padding(.init(top: 16, left: 0, bottom: 25, right: 0))
                        createNetworkView(network: .bitcoin)
                    }
                }
            }
        }

        private func createNetworkView(network: SendToken.Network) -> _NetworkView {
            _NetworkView()
                .setup { view in
                    Driver.combineLatest(
                        viewModel.feeInfoDriver,
                        viewModel.payingWalletDriver
                    )
                        .drive(onNext: { [weak view, weak self] feeInfo, payingWallet in
                            view?.setUp(
                                network: network,
                                payingWallet: payingWallet,
                                feeInfo: feeInfo.value,
                                prices: self?.viewModel.getPrices(for: ["SOL", "renBTC"]) ?? [:]
                            )
                        })
                        .disposed(by: disposeBag)

                    selectedNetwork.asDriver()
                        .map { $0 != network }
                        .drive(view.tickView.rx.isHidden)
                        .disposed(by: disposeBag)
                }
                .onTap { [unowned self] in self.switchNetwork(to: network) }
        }

        private func switchNetwork(to network: SendToken.Network) {
            let networkName = viewModel.getSelectedNetwork().rawValue.uppercaseFirst

            showAlert(
                title: L10n.changeTheNetwork,
                message: L10n.ifTheNetworkIsChangedToTheAddressFieldMustBeFilledInWithA(
                    networkName,
                    L10n.compatibleAddress(networkName)
                ),
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
        fileprivate lazy var tickView = UIImageView(width: 14.3, height: 14.19, image: .tick, tintColor: .h5887ff)

        override init() {
            super.init()
            addArrangedSubview(tickView)
        }
    }
}
