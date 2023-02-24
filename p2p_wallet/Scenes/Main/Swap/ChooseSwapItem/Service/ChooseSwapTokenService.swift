import Resolver

final class ChooseSwapTokenService: ChooseItemService {

    var chosenTokenTitle: String = L10n.chosenToken.uppercased()
    var otherTokensTitle: String = L10n.allTokens.uppercased()

    private let swapTokens: [SwapToken]
    init(swapTokens: [SwapToken]) {
        self.swapTokens = swapTokens
    }

    func fetchItems() async throws -> [ChooseItemListSection] {
        let firstSection = swapTokens.filter({ $0.userWallet != nil })
        let secondSection = swapTokens.filter({ $0.userWallet == nil })
        return [ChooseItemListSection(items: firstSection), ChooseItemListSection(items: secondSection)]
    }

    func sort(items: [ChooseItemListSection]) -> [ChooseItemListSection] {
        let newItems = items.map { section in
            guard let tokens = section.items as? [SwapToken] else { return section }
            return ChooseItemListSection(items: tokens.sorted())
        }
        let isEmpty = newItems.flatMap({ $0.items }).isEmpty
        return isEmpty ? [] : newItems
    }
}

private extension Array where Element == SwapToken {
    func sorted() -> Self {
        let preferOrder: [String: Int] = ["USDC": 1, "USDT": 2]
        return self
            .sorted { (lhs: SwapToken, rhs: SwapToken) -> Bool in
                if preferOrder[lhs.token.symbol] != nil || preferOrder[rhs.token.symbol] != nil {
                    return (preferOrder[lhs.token.symbol] ?? 3) < (preferOrder[rhs.token.symbol] ?? 3)
                } else if let lhsWallet = lhs.userWallet, let rhsWallet = rhs.userWallet {
                    return lhsWallet.amountInCurrentFiat > rhsWallet.amountInCurrentFiat
                } else if lhs.userWallet != nil || rhs.userWallet != nil {
                    return false
                } else {
                    return lhs.token.name < rhs.token.name
                }
            }
    }
}
