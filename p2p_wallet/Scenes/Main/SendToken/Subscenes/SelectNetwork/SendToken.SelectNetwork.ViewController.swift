//
//  SendToken.SelectNetwork.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/12/2021.
//

import Combine
import Foundation

extension SendToken.SelectNetwork {
    final class ViewController: BaseViewController {
        private let viewModel: SendTokenSelectNetworkViewModelType
        private var subscriptions = [AnyCancellable]()

        // Internal state
        private let selectedNetwork: CurrentValueSubject<SendToken.Network, Never>

        init(viewModel: SendTokenSelectNetworkViewModelType) {
            self.viewModel = viewModel
            selectedNetwork = .init(viewModel.getSelectedNetwork())
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
                                    Task {
                                        let maxUsage = try await viewModel.getFreeTransactionFeeLimit().maxUsage
                                        await MainActor.run {[weak label] in
                                            label?.text = L10n.OnTheSolanaNetworkTheFirstTransactionsInADayArePaidByKeyApp
                                                .subsequentTransactionsWillBeChargedBasedOnTheSolanaBlockchainGasFee(
                                                    maxUsage
                                                )
                                        }
                                    }
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
                    Publishers.CombineLatest(
                        viewModel.feeInfoPublisher,
                        viewModel.payingWalletPublisher
                    )
                        .receive(on: RunLoop.main)
                        .sink { [weak view, weak self] feeInfo, payingWallet in
                            view?.setUp(
                                network: network,
                                payingWallet: payingWallet,
                                feeInfo: feeInfo.value,
                                prices: self?.viewModel.getPrices(for: ["SOL", "renBTC"]) ?? [:]
                            )
                        }
                        .store(in: &subscriptions)

                    selectedNetwork
                        .map { $0 != network }
                        .assign(to: \.isHidden, on: view.tickView)
                        .store(in: &subscriptions)
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
                    self?.selectedNetwork.send(network)
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
