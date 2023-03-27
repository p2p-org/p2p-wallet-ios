//
//  EthereumAccountStore.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 17.03.2023.
//

import Foundation
import KeyAppKitCore
import Web3
import Wormhole

class EthereumAccountsDataSource: ObservableObject {
    struct Account {
        let account: EthereumAccount
        let wormholeBundle: WormholeBundleStatus?
    }

    // This function aggregates Ethereum accounts with their corresponding Wormhole bundle status
    static func aggregate(
        accounts: [EthereumAccount],
        wormholeBundlesStatus: [WormholeBundleStatus]
    ) -> [Account] {
        accounts.map { account in
            // Get the corresponding Wormhole bundle status for this Ethereum account
            let bundleStatus: WormholeBundleStatus? = wormholeBundlesStatus.first { bundle in
                switch (account.token.contractType, bundle.resultAmount.token) {
                case let (.native, .ethereum(contract)):
                    // If the account is for the native token, check if the bundle token is nil
                    return contract == nil

                case let (.erc20(accountContract), .ethereum(bundleContract)):
                    // If the account is for an ERC-20 token, check if the bundle token matches
                    return accountContract == (try? EthereumAddress(hex: bundleContract ?? "", eip55: false))

                default:
                    // Other cases
                    return false
                }
            }

            return Account(
                account: account,
                wormholeBundle: bundleStatus
            )
        }
    }
}