//
//  WormhyoleSendInputCoordinator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 22.03.2023.
//

import Foundation
import Send
import SwiftUI
import SolanaSwift

class WormholeSendInputCoordinator: SmartCoordinator<String> {
    let recipient: Recipient

    init(recipient: Recipient, from: UINavigationController) {
        self.recipient = recipient
        super.init(presentation: SmartCoordinatorPushPresentation(from))
    }

    override func build() -> UIViewController {
        let viewModel = WormholeSendInputViewModel(recipient: recipient)
        let view = WormholeSendInputView(viewModel: viewModel)
        let vc = UIHostingController(rootView: view)

        viewModel.changeTokenPressed
            .sink { [weak self] in
                self?.openChooseWormholeToken(from: vc, viewModel: viewModel)
            }
            .store(in: &subscriptions)

        return vc
    }

    private func openChooseWormholeToken(from vc: UIViewController, viewModel: WormholeSendInputViewModel) {
        coordinate(to: ChooseWormholeTokenCoordinator(
            chosenWallet: Wallet(token: Token.nativeSolana), // TODO: HARDCODE, fix after logic is done
            parentController: vc
        ))
        .sink { walletToken in
            if let walletToken = walletToken {
                // TODO: fix after logic is done
            }
        }
        .store(in: &subscriptions)
    }
}
