import BankTransfer
import Foundation
import KeyAppBusiness
import Resolver
import Wormhole

class HomeAccountsSynchronisationService {
    @Injected var solanaAccountsService: SolanaAccountsService
    @Injected var ethereumAccountsService: EthereumAccountsService
    @Injected var priceService: PriceService
    @Injected var userActionService: UserActionService
    @Injected var bankTransfer: any BankTransferService

    func refresh() async {
        // Update wormhole
        userActionService.handle(event: WormholeClaimUserActionEvent.refresh)
        async let _ = (
            try? await priceService.clear(),
            try? await solanaAccountsService.fetch(),
            try? await ethereumAccountsService.fetch(),
            try? await loadEthereumAccountsService()
        )
        await bankTransfer.reload()
    }

    func loadEthereumAccountsService() async throws {
        guard available(.ethAddressEnabled) else { return }
        try await ethereumAccountsService.fetch()
    }
}
