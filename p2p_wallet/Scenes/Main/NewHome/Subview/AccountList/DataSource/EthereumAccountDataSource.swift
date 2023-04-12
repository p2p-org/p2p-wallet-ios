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
                    switch (account.token.contractType, userAction.token.contractType) {
                    case (.native, .native):
                        // If the account is for the native token, check if the bundle token is nil
                        return true

                    case let (.erc20(lhsContract), .erc20(rhsContract)):
                        // Check matching erc-20 tokens
                        return lhsContract == rhsContract

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
