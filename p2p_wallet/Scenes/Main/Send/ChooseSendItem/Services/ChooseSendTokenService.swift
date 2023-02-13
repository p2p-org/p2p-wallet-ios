import SolanaSwift
import Resolver

final class ChooseSendTokenService: ChooseItemService {

    @Injected private var walletsRepository: WalletsRepository

    func fetchItems() async throws -> [ChooseItemListData] {
        let wallets = walletsRepository.getWallets().filter { wallet in
            (wallet.lamports ?? 0) > 0 && !wallet.isNFTToken
        }
        return [ChooseItemListData(id: .init(), items: wallets)]
    }

    func filterAndSort(items: [ChooseItemListData], by keyword: String) -> [ChooseItemListData] {
        items.map { section in
            return ChooseItemListData(id: .init(), items: (section.items as! [Wallet]).filteredAndSorted(byKeyword: keyword))
        }
    }
}


