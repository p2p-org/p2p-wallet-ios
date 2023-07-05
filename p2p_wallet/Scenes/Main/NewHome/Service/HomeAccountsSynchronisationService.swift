import Foundation
import KeyAppBusiness
import Resolver
import Wormhole
import BankTransfer

class HomeAccountsSynchronisationService {
    @Injected var solanaAccountsService: SolanaAccountsService
    @Injected var ethereumAccountsService: EthereumAccountsService
    @Injected var userActionService: UserActionService
    @Injected var bankTransfer: any BankTransferService

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

                if available(.bankTransfer) {
                    group.addTask { [weak self] in
                        guard let self else { return }
                        await self.bankTransfer.reload()
                    }
                }

                // another chains goes here

                // await values
                for try await _ in group {}
            }
        } catch {}
    }
}
