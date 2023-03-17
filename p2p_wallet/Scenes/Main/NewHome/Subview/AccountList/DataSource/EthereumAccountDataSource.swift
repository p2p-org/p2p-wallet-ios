//
//  EthereumAccountStore.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 17.03.2023.
//

import Foundation
import KeyAppBusiness
import Wormhole

class EthereumAccountsDataSource: ObservableObject {
    struct Account {
        let account: EthereumAccountsService.Account
        let wormholeBundle: WormholeBundleStatus?
    }

    static func aggregate(
        accounts: [EthereumAccountsService.Account],
        wormholeBundlesStatus: [WormholeBundleStatus]
    ) -> [Account] {
        accounts.map { account in
            let bundleStatus: WormholeBundleStatus? = wormholeBundlesStatus.first {
                switch account.token.contractType {
                case .native:
                    return $0.token == nil
                case let .erc20(contract):
                    return $0.token == contract.hex(eip55: false)
                }
            }

            return Account(
                account: account,
                wormholeBundle: bundleStatus
            )
        }
    }
}
