//
//  HomeAccountsSynchornisationService.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 19.04.2023.
//

import Foundation
import KeyAppBusiness
import Resolver
import Wormhole

class HomeAccountsSynchronisationService {
    @Injected var solanaAccountsService: SolanaAccountsService
    @Injected var ethereumAccountsService: EthereumAccountsService
    @Injected var userActionService: UserActionService

    func refresh() async {
        // Update wormhole
        userActionService.handle(event: WormholeClaimUserActionEvent.refresh)

        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                // solana
                group.addTask { [weak self] in
                    guard let self else { return }
                    try await self.solanaAccountsService.fetch()
                }

                // ethereum
                if available(.ethAddressEnabled) {
                    group.addTask { [weak self] in
                        guard let self else { return }
                        try await self.ethereumAccountsService.fetch()
                    }
                }

                // another chains goes here

                // await values
                for try await _ in group {}
            }
        } catch {}
    }
}
