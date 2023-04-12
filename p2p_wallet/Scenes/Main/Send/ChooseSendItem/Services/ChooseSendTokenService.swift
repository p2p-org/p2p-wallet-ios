import SolanaSwift
import Resolver

final class ChooseSendTokenService: ChooseItemService {

    let otherTokensTitle = L10n.otherTokens

    @Injected private var walletsRepository: WalletsRepository

    func fetchItems() async throws -> [ChooseItemListSection] {
        let wallets = walletsRepository.getWallets().filter { wallet in
            (wallet.lamports ?? 0) > 0 && !wallet.isNFTToken
        }
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


