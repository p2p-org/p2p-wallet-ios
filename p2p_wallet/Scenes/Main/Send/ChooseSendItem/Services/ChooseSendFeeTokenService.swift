import SolanaSwift

final class ChooseSendFeeTokenService: ChooseItemService {

    var chosenTokenTitle: String = L10n.chosenToken
    var otherTokensTitle: String = L10n.otherTokens

    private let tokens: [Wallet]
    init(tokens: [Wallet]) {
        self.tokens = tokens
    }

    func fetchItems() async throws -> [ChooseItemListSection] {
        [ChooseItemListSection(items: tokens)]
    }

    func filterAndSort(items: [ChooseItemListSection], by keyword: String) -> [ChooseItemListSection] {
        let newItems = items.map { section in
            ChooseItemListSection(items: (section.items as! [Wallet]).filteredAndSorted(byKeyword: keyword))
        }
        let isEmpty = newItems.flatMap({ $0.items }).isEmpty
        return isEmpty ? [] : newItems
    }
}
