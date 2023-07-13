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
        async let (_, _) = (
            try? await solanaAccountsService.fetch(),
            try? await ethereumAccountsService.fetch()
        )
        await bankTransfer.reload()
    }
}
