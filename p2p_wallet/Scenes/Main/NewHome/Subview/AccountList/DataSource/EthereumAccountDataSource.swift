//
//  EthereumAccountStore.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 17.03.2023.
//

import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Web3
import Wormhole

class EthereumAccountsDataSource: ObservableObject {
    struct Account {
        let account: EthereumAccount
        let isClaiming: Bool
    }

    // This function aggregates Ethereum accounts with their corresponding Wormhole bundle status
    static func aggregate(
        accounts: [EthereumAccount],
        claimUserActions: [WormholeClaimUserAction]
    ) -> [Account] {
        accounts.map { account in
            // Get the corresponding Wormhole bundle status for this Ethereum account
            let bundleStatus: WormholeClaimUserAction? = claimUserActions
                .filter {
                    switch $0.status {
                    case .pending, .processing:
                        return true
                    default:
                        return false
                    }
                }
                .first { userAction in
                    switch (account.token.contractType, userAction.bundle.resultAmount.token) {
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
                isClaiming: bundleStatus != nil
            )
        }
    }
}
