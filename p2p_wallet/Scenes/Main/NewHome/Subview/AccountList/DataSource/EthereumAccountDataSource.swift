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

    // This function aggregates Ethereum accounts with their corresponding Wormhole bundle status
    static func aggregate(
        accounts: [EthereumAccountsService.Account],
        wormholeBundlesStatus: [WormholeBundleStatus]
    ) -> [Account] {
        accounts.map { account in
            // Get the corresponding Wormhole bundle status for this Ethereum account
            let bundleStatus: WormholeBundleStatus? = wormholeBundlesStatus.first { bundle in
                switch account.token.contractType {
                case .native:
                    // If the account is for the native token, check if the bundle token is nil
                    return bundle.token == nil

                case let .erc20(contract):
                    // If the account is for an ERC-20 token, check if the bundle token matches
                    return bundle.token == contract.hex(eip55: false)
                }
            }

            return Account(
                account: account,
                wormholeBundle: bundleStatus
            )
        }
    }
}
