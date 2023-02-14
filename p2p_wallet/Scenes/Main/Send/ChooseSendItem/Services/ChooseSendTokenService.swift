import SolanaSwift
import Resolver

final class ChooseSendTokenService: ChooseItemService {

    var chosenTokenTitle: String = L10n.chosenToken
    var otherTokensTitle: String = L10n.otherTokens

    @Injected private var walletsRepository: WalletsRepository

    func fetchItems() async throws -> [ChooseItemListSection] {
        let wallets = walletsRepository.getWallets().filter { wallet in
            (wallet.lamports ?? 0) > 0 && !wallet.isNFTToken
        }
        return [ChooseItemListSection(items: wallets)]
    }

    func filterAndSort(items: [ChooseItemListSection], by keyword: String) -> [ChooseItemListSection] {
        let newItems = items.map { section in
            ChooseItemListSection(items: (section.items as! [Wallet]).filteredAndSorted(byKeyword: keyword))
        }
        let isEmpty = newItems.flatMap({ $0.items }).isEmpty
        return isEmpty ? [] : newItems
    }
}


