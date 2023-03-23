import Resolver
import KeyAppBusiness
import Combine
import SolanaSwift
import Wormhole

final class ChooseWormholeTokenService: ChooseItemService {

    let otherTokensTitle = L10n.otherTokens

    @Injected private var accountsService: SolanaAccountsService

    func fetchItems() async throws -> [ChooseItemListSection] {
        // TODO: Add possibility to handle accountsService.state publisher and update ChooseItemService accordingly
        let wallets = accountsService.state.value
            .filter {
                !$0.data.isNFTToken &&
                $0.data.amount > 0 &&
                SupportedToken.ERC20.allCases.map { $0.solanaMintAddress }.contains($0.data.mintAddress)
            }
            .map { $0.data }
        return [ChooseItemListSection(items: wallets)]
    }

    func sort(items: [ChooseItemListSection]) -> [ChooseItemListSection] {
        let newItems = items.map { section in
            guard let wallets = section.items as? [Wallet] else { return section }
            return ChooseItemListSection(items: wallets.sorted())
        }
        let isEmpty = newItems.flatMap({ $0.items }).isEmpty
        return isEmpty ? [] : newItems
    }

    func sortFiltered(by keyword: String, items: [ChooseItemListSection]) -> [ChooseItemListSection] {
        sort(items: items)
    }
}
