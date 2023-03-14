//
//  WormholeClaimFeeCoordinator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 12.03.2023.
//

import Foundation
import KeyAppBusiness
import KeyAppKitCore
import KeychainSwift
import Wormhole

class WormholeClaimFeeCoordinator: SmartCoordinator<Void> {
    let account: EthereumAccountsService.Account
    let bundle: AsyncValue<WormholeBundle?>

    init(account: EthereumAccountsService.Account, bundle: AsyncValue<WormholeBundle?>, presentation: SmartCoordinatorPresentation) {
        self.account = account
        self.bundle = bundle
        super.init(presentation: presentation)
    }

    override func build() -> UIViewController {
        let vm = WormholeClaimFeeViewModel(account: account, bundle: bundle)

        vm.closeAction.sink { [weak self] _ in
            self?.presentation.presentingViewController.dismiss(animated: true)
        }
        .store(in: &subscriptions)

        let view = WormholeClaimFee(viewModel: vm)
        return BottomSheetController(rootView: view)
    }
}
