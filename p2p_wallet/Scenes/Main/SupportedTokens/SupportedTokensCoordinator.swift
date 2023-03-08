//
//  SupportedTokensCoordinator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 08.03.2023.
//

import Foundation
import SwiftUI

class SupportedTokensCoordinator: SmartCoordinator<Void> {
    override func build() -> UIViewController {
        let vm = SupportedTokensViewModel()

        vm.actionSubject
            .sink { [weak self] action in
                guard let self = self else { return }

                switch action {
                case let .receive(item):
                    self.openReceive(item: item)
                }
            }
            .store(in: &subscriptions)

        let view = SupportedTokensView(viewModel: vm)

        let vc = UIHostingController(rootView: view)
        vc.title = L10n.supportedTokens

        return vc
    }

    func openReceive(item: SupportedTokenItem) {
        func _openReceive(network: ReceiveNetwork) {
            self.coordinate(to: ReceiveCoordinator(network: network, presentation: self.presentation))
                .sink {}
                .store(in: &subscriptions)
        }

        if item.availableNetwork.count == 1, let network = item.availableNetwork.first {
            switch network {
            case .solana:
                _openReceive(network: .solana(tokenSymbol: item.symbol))
            case .ethereum:
                _openReceive(network: .ethereum(tokenSymbol: item.symbol))
            }
        } else {
            let coordinator = SupportedTokenNetworksCoordinator(supportedToken: item, viewController: self.presentation.presentingViewController)
            self.coordinate(to: coordinator)
                .sink { selectedNetwork in
                    guard let selectedNetwork else { return }
                    switch selectedNetwork {
                    case .solana:
                        _openReceive(network: .solana(tokenSymbol: item.symbol))
                    case .ethereum:
                        _openReceive(network: .ethereum(tokenSymbol: item.symbol))
                    }
                }
                .store(in: &subscriptions)
        }
    }
}
