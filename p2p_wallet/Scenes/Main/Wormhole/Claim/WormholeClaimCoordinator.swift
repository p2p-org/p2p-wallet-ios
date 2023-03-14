//
//  WormholeClaimCoordinator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 11.03.2023.
//

import Foundation
import KeyAppBusiness
import SwiftUI

enum WormholeClaimCoordinatorResult {
    case claiming(PendingTransaction)
}

class WormholeClaimCoordinator: SmartCoordinator<WormholeClaimCoordinatorResult> {
    let account: EthereumAccountsService.Account

    init(account: EthereumAccountsService.Account, presentation: SmartCoordinatorPresentation) {
        self.account = account
        super.init(presentation: presentation)
    }

    override func build() -> UIViewController {
        let vm = WormholeClaimViewModel(account: account)
        vm.action
            .sink { [weak self] action in
                guard let self = self else { return }
                switch action {
                case let .openFee(bundle):
                    self.coordinate(to: WormholeClaimFeeCoordinator(
                        account: self.account,
                        bundle: bundle,
                        presentation: SmartCoordinatorPresentPresentation(from: self.presentation))
                    )
                    .sink { _ in }
                    .store(in: &self.subscriptions)
                case let .claiming(trx):
                    self.pop(.claiming(trx))
                }
            }
            .store(in: &subscriptions)

        let view = WormholeClaimView(viewModel: vm)

        let vc = UIHostingController(rootView: view)
        vc.title = L10n.claim(account.token.symbol)
        vc.hidesBottomBarWhenPushed = true

        return vc
    }
}
