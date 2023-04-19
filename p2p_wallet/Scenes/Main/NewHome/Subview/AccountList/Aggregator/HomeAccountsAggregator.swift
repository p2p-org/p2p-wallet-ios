//
//  HomeDataAggregator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 18.04.2023.
//

import Foundation
import KeyAppKitCore
import Web3
import Wormhole

protocol Aggregator<Input, Output> {
    associatedtype Input
    associatedtype Output

    func transform(input: Input) -> Output
}

struct HomeAccountsAggregator: Aggregator {
    func transform(
        input: (
            solanaAccounts: [RendableSolanaAccount],
            ethereumAccounts: [RenderableEthereumAccount]
        )
    )
    -> (primary: [any RendableAccount], secondary: [any RendableAccount]) {
        let (solanaAccounts, ethereumAccounts) = input

        let mergedAccounts: [any RendableAccount] = ethereumAccounts + solanaAccounts

        func primaryFilter(account: any RendableAccount) -> Bool {
            if account.tags.contains(.favourite) {
                return true
            }

            if account.tags.contains(.ignore) {
                return false
            }

            return true
        }

        let primaryAccounts = mergedAccounts.filter(primaryFilter)
        let secondaryAccounts = mergedAccounts.filter { !primaryFilter(account: $0) }

        return (primaryAccounts, secondaryAccounts)
    }
}
