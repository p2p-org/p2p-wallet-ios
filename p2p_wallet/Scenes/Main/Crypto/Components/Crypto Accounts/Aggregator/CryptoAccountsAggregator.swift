import Foundation
import KeyAppKitCore
import Web3
import Wormhole
import BigDecimal

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
        
        // Claimable transfer accounts
        let transferAccounts = allEthereumAccounts.filter { ethAccount in
            switch ethAccount.status {
            case .ready, .isProcessing:
                return true
            default:
                return false
            }
        }
        
        // Ethereum accounts without claimable transfers
        let filteredEthereumAccounts = allEthereumAccounts.filter { account in
            return !transferAccounts.contains(account)
        }

        let mergedNonTransferAccounts: [any RenderableAccount] = (filteredEthereumAccounts + solanaAccounts)
            .filter(hiddenFilter)
            .sorted(by: commonSort)
        
        let primaryAccounts = mergedNonTransferAccounts
            .filter(primaryFilter)
        
        let secondaryAccounts = mergedNonTransferAccounts
            .filter { !primaryFilter(account: $0) }

        return (transferAccounts, primaryAccounts, secondaryAccounts)
    }
    
    // MARK: - Helpers
    
    /// Filter out hidden accounts
    func hiddenFilter(account: any RenderableAccount) -> Bool {
        !account.tags.contains(.hidden)
    }

    /// Split into two groups
    func primaryFilter(account: any RenderableAccount) -> Bool {
        if account.tags.contains(.favourite) {
            return true
        }

        if account.tags.contains(.ignore) {
            return false
        }
        return true
    }
    
    /// Sort by sorting key
    func commonSort(lhs: any SortableAccount, rhs: any SortableAccount) -> Bool {
        guard
            let lhsKey = lhs.sortingKey,
            let rhsKey = rhs.sortingKey
        else { return false }
        
        return lhsKey > rhsKey
    }
}
