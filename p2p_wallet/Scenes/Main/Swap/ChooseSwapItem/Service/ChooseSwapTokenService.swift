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

    func filterAndSort(items: [ChooseItemListSection], by keyword: String) -> [ChooseItemListSection] {
        var newItems = items
        if !keyword.isEmpty {
            // Do not split up sections if there is a keyword
            newItems = [ChooseItemListSection(items: newItems.flatMap({ $0.items }))]
        }
        newItems = newItems.map { section in
            ChooseItemListSection(
                items: (section.items as! [SwapToken]).filteredAndSorted(byKeyword: keyword)
            )
        }
        let isEmpty = newItems.flatMap({ $0.items }).isEmpty
        return isEmpty ? [] : newItems
    }
}

private extension Array where Element == SwapToken {
    func filteredAndSorted(byKeyword keyword: String = "") -> Self {
        var swapTokens = self

        if !keyword.isEmpty {
            let keyword = keyword.lowercased()
            swapTokens = swapTokens.filter { $0.matches(keyword: keyword) }
        }

        let preferOrder: [String: Int] = ["USDC": 1, "USDT": 2]
        return swapTokens
            .sorted { (lhs: SwapToken, rhs: SwapToken) -> Bool in
                if preferOrder[lhs.jupiterToken.symbol] != nil || preferOrder[rhs.jupiterToken.symbol] != nil {
                    return (preferOrder[lhs.jupiterToken.symbol] ?? 3) < (preferOrder[rhs.jupiterToken.symbol] ?? 3)
                } else if let lhsWallet = lhs.userWallet, let rhsWallet = rhs.userWallet {
                    return lhsWallet.amountInCurrentFiat > rhsWallet.amountInCurrentFiat
                } else {
                    return lhs.jupiterToken.name < rhs.jupiterToken.name
                }
            }
    }
}
