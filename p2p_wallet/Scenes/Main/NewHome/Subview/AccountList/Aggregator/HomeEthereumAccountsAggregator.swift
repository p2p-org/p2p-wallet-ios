//
//  HomeAggregator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 18.04.2023.
//

import Foundation
import KeyAppKitCore
import Web3
import Wormhole

/// Aggregating ``EthereumAccount`` into ``RendableAccount``.
struct HomeEthereumAccountsAggregator: DataAggregator {
    func transform(
        input: ([EthereumAccount], [WormholeClaimUserAction])
    ) -> [RenderableEthereumAccount] {
        let (accounts, claims) = input

        // Filter
        let filteredAccounts = EthereumAccountsWithWormholeAggregator()
            .transform(input: accounts)

        // Transform to RendableAccount
        let claimBindingAggregator = EthereumAccountsBindWithClaims()
        let renderableAccounts = filteredAccounts
            .map { account in
                claimBindingAggregator.transform(input: (account, claims))
            }
            .map { account, claiming in
                let status: RenderableEthereumAccount.Status

                if claiming == nil {
                    // Extract balance from account
                    let balanceInFiat = account.balanceInFiat

                    if let balanceInFiat {
                        // Compare using fiat.
                        if balanceInFiat >= CurrencyAmount(usd: 1) {
                            // Balance is greater than $1, user can claim.
                            status = .readyToClaim
                        } else {
                            // Balance is to low.
                            status = .balanceToLow
                        }
                    } else {
                        // Compare using crypto amount.
                        if account.balance > 0 {
                            // Balance is not zero
                            status = .readyToClaim
                        } else {
                            // Balance is to low.
                            status = .balanceToLow
                        }
                    }

                } else {
                    // Claiming is running.
                    status = .isClamming
                }

                return RenderableEthereumAccount(
                    account: account,
                    status: status
                )
            }

        return renderableAccounts
    }
}

/// Mapping ethereum account with current claim user action.
///
/// Only action in pending or processing will be mapped.
private struct EthereumAccountsBindWithClaims: DataAggregator {
    func transform(
        input: (EthereumAccount, [WormholeClaimUserAction])
    ) -> (EthereumAccount, WormholeClaimUserAction?) {
        let (account, claims) = input

        // Get the corresponding Wormhole bundle status for this Ethereum account
        let bundleStatus: WormholeClaimUserAction? = claims
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

        return (account, bundleStatus)
    }
}

/// Filter ethereum accounts with supported erc-20 token list.
private struct EthereumAccountsWithWormholeAggregator: DataAggregator {
    func transform(input: [EthereumAccount]) -> [EthereumAccount] {
        input
            .filter { account in
                // Filter accounts by supported wormhole list.
                switch account.token.contractType {
                case .native:
                    // We always support native token
                    return true
                case let .erc20(contract):
                    // Check erc-20 tokens
                    return WormholeSupportedTokens.bridges.contains { bridge in
                        if let bridgeTokenAddress = bridge.ethAddress {
                            // Supported bridge token is erc-20
                            return (try? EthereumAddress(hex: bridgeTokenAddress, eip55: false)) == contract
                        } else {
                            // Supported bridge token is native.
                            return false
                        }
                    }
                }
            }
    }
}
