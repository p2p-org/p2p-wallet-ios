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

    func sort(items: [ChooseItemListSection]) -> [ChooseItemListSection] {
        let newItems = items.map { section in
            guard let wallets = section.items as? [Wallet] else { return section }
            return ChooseItemListSection(items: wallets.sorted())
        }
        let isEmpty = newItems.flatMap({ $0.items }).isEmpty
        return isEmpty ? [] : newItems
    }
}
