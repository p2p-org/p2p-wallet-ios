//
//  CryptoAccountsAggregator.swift
//  p2p_wallet
//
//  Created by Zafar Ivaev on 13/07/23.
//

import Foundation
import KeyAppKitCore
import Web3
import Wormhole

struct CryptoAccountsAggregator: DataAggregator {
    func transform(
        input: (
            solanaAccounts: [RenderableSolanaAccount],
            ethereumAccounts: [RenderableEthereumAccount]
        )
    )
    -> (primary: [any RenderableAccount], secondary: [any RenderableAccount], transfers: [any RenderableAccount]) {
        let (solanaAccounts, ethereumAccounts) = input

        var mergedAccounts: [any RenderableAccount] = ethereumAccounts + solanaAccounts

        // Filter hidden accounts
        mergedAccounts = mergedAccounts.filter { account in
            if account.tags.contains(.hidden) {
                return false
            }

            return true
        }

        // Split into two groups
        func primaryFilter(account: any RenderableAccount) -> Bool {
            if account.tags.contains(.favourite) {
                return true
            }

            if account.tags.contains(.ignore) {
                return false
            }
            return true
        }
        
        func commonFilter(account: any RenderableAccount) -> Bool {
            if case .button = account.detail {
                return false
            }
            return true
        }

        let primaryAccounts = mergedAccounts
            .filter(primaryFilter)
            .filter(commonFilter)
            .sorted { lhs, rhs in
                guard
                    let lhsKey = lhs.sortingKey,
                    let rhsKey = rhs.sortingKey
                else { return false }
                
                return lhsKey > rhsKey
            }
        let secondaryAccounts = mergedAccounts
            .filter { !primaryFilter(account: $0) }
            .filter(commonFilter)
            .sorted { lhs, rhs in
                guard
                    let lhsKey = lhs.sortingKey,
                    let rhsKey = rhs.sortingKey
                else { return false }
                
                return lhsKey > rhsKey
            }
        let transferAccounts = mergedAccounts
            .filter { !commonFilter(account: $0) }

        return (primaryAccounts, secondaryAccounts, transferAccounts)
    }
}
