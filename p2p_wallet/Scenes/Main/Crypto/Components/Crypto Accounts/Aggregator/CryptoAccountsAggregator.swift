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
    typealias Input = (
        solanaAccounts: [RenderableSolanaAccount],
        ethereumAccounts: [RenderableEthereumAccount]
    )
    typealias Output = (
        transfers: [any RenderableAccount],
        primary: [any RenderableAccount],
        secondary: [any RenderableAccount]
    )
    
    func transform(input: Input) -> Output {
        let (solanaAccounts, allEthereumAccounts) = input
        
        /// Claimable transfer accounts
        let transferAccounts = allEthereumAccounts.filter { ethAccount in
            switch ethAccount.status {
            case .readyToClaim, .isClaiming:
                return true
            default:
                return false
            }
        }
        
        /// Ethereum accounts without claimable transfers
        let filteredEthereumAccounts = allEthereumAccounts.filter { account in
            return transferAccounts.contains(account)
        }

        var mergedNonTransferAccounts: [any RenderableAccount] = filteredEthereumAccounts + solanaAccounts

        let primaryAccounts = mergedNonTransferAccounts
            .filter(hiddenFilter)
            .filter(primaryFilter)
            .sorted(by: commonSort)
        
        let secondaryAccounts = mergedNonTransferAccounts
            .filter(hiddenFilter)
            .filter { !primaryFilter(account: $0) }
            .sorted(by: commonSort)

        return (transferAccounts, primaryAccounts, secondaryAccounts)
    }
    
    // MARK: - Helpers
    
    // Filter out hidden accounts
    func hiddenFilter(account: any RenderableAccount) -> Bool {
        !account.tags.contains(.hidden)
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
    
    // Sort by sorting key
    func commonSort(lhs: any RenderableAccount, rhs: any RenderableAccount) -> Bool {
        guard
            let lhsKey = lhs.sortingKey,
            let rhsKey = rhs.sortingKey
        else { return false }
        
        return lhsKey > rhsKey
    }
}
