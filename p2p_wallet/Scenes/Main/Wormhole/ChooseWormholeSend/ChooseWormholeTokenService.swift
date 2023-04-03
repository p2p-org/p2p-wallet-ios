import Combine
import KeyAppBusiness
import Resolver
import SolanaSwift
import Wormhole

final class ChooseWormholeTokenService: ChooseItemService {
    let otherTokensTitle = L10n.otherTokens

    @Injected private var accountsService: SolanaAccountsService

    func fetchItems() async throws -> [ChooseItemListSection] {
        // TODO: Add possibility to handle accountsService.state publisher and update ChooseItemService accordingly
        let wallets = accountsService.state.value
            .filter {
                SupportedToken.bridges.map(\.solAddress).contains($0.data.mintAddress)
            }
            .map(\.data)
        return [ChooseItemListSection(items: wallets)]
    }

    func sort(items: [ChooseItemListSection]) -> [ChooseItemListSection] {
        let newItems = items.map { section in
            guard let wallets = section.items as? [Wallet] else { return section }
            return ChooseItemListSection(items: wallets.sorted())
        }
        let isEmpty = newItems.flatMap(\.items).isEmpty
        return isEmpty ? [] : newItems
    }

    func sortFiltered(by _: String, items: [ChooseItemListSection]) -> [ChooseItemListSection] {
        sort(items: items)
    }
}
