import SolanaSwift

final class ChooseSendFeeTokenService: ChooseItemService {

    private let tokens: [Wallet]
    init(tokens: [Wallet]) {
        self.tokens = tokens
    }

    func fetchItems() async throws -> [ChooseItemListData] {
        [ChooseItemListData(id: .init(), items: tokens)]
    }

    func filterAndSort(items: [ChooseItemListData], by keyword: String) -> [ChooseItemListData] {
        items.map { section in
            return ChooseItemListData(id: .init(), items: (section.items as! [Wallet]).filteredAndSorted(byKeyword: keyword))
        }
    }
}
