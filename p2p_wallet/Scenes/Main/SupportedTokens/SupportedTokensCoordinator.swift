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
        vc.hidesBottomBarWhenPushed = true
        vc.title = L10n.supportedTokens

        return vc
    }

    func openReceive(item: SupportedTokenItem) {
        // Coordinate to receive
        func _openReceive(network: ReceiveNetwork) {
            self.coordinate(to: ReceiveCoordinator(network: network, presentation: self.presentation))
                .sink {}
                .store(in: &subscriptions)
        }

        var image: ReceiveNetwork.Image? = .init(icon: item.icon)

        if item.availableNetwork.count == 1, let network = item.availableNetwork.first {
            // Token supports only one network.
            switch network {
            case .solana:
                _openReceive(network: .solana(tokenSymbol: item.symbol, tokenImage: image))
            case .ethereum:
                _openReceive(network: .ethereum(tokenSymbol: item.symbol, tokenImage: image))
            }
        } else {
            // Token supports many networks.
            let coordinator = SupportedTokenNetworksCoordinator(supportedToken: item, viewController: self.presentation.presentingViewController)
            self.coordinate(to: coordinator)
                .sink { selectedNetwork in
                    guard let selectedNetwork else { return }
                    switch selectedNetwork {
                    case .solana:
                        _openReceive(network: .solana(tokenSymbol: item.symbol, tokenImage: image))
                    case .ethereum:
                        _openReceive(network: .ethereum(tokenSymbol: item.symbol, tokenImage: image))
                    }
                }
                .store(in: &subscriptions)
        }
    }
}

extension ReceiveNetwork.Image {
    init?(icon: SupportedTokenItemIcon) {
        switch icon {
        case let .url(url):
            self = .url(url)
        case let .image(uiImage):
            self = .image(uiImage)
        case .placeholder:
            return nil
        }
    }
}
