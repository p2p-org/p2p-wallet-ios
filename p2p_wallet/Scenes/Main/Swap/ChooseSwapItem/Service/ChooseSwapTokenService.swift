import Resolver

final class ChooseSwapTokenService: ChooseItemService {

    let chosenTokenTitle: String = L10n.chosenToken.uppercased()
    let otherTokensTitle: String = L10n.allTokens.uppercased()

    private let swapTokens: [SwapToken]
    private let fromToken: Bool

    private let preferTokens: [String]

    init(swapTokens: [SwapToken], fromToken: Bool) {
        self.swapTokens = swapTokens
        self.fromToken = fromToken

        if fromToken {
            preferTokens = ["USDC", "USDT"]
        } else {
            preferTokens = SwapToken.preferTokens
        }
    }

    func fetchItems() async throws -> [ChooseItemListSection] {
        var firstSection = [SwapToken]()
        var secondSection = [SwapToken]()
        if fromToken {
            firstSection = swapTokens.filter { $0.userWallet != nil }
            secondSection = swapTokens.filter { $0.userWallet == nil }
        } else {
            let preferTokens = Set(self.preferTokens)
            swapTokens.forEach {
                if preferTokens.contains($0.token.symbol) {
                    firstSection.append($0)
                } else {
                    secondSection.append($0)
                }
            }
        }
        return [
            ChooseItemListSection(items: firstSection),
            ChooseItemListSection(items: secondSection)
        ]
    }

    func sort(items: [ChooseItemListSection]) -> [ChooseItemListSection] {
        let newItems = items.map { section in
            guard let tokens = section.items as? [SwapToken] else { return section }
            return ChooseItemListSection(items: tokens.sorted(
                preferTokens: preferTokens,
                sortByName: !fromToken
            ))
        }
        let isEmpty = newItems.flatMap { $0.items }.isEmpty
        return isEmpty ? [] : newItems
    }
}

// MARK: - Sort Rules

private extension Array where Element == SwapToken {
    func sorted(preferTokens: [String], sortByName: Bool) -> Self {
        var preferOrder = [String: Int]()
        preferTokens.enumerated().forEach {
            preferOrder[$0.1] = $0.0 + 1
        }
        return sorted { (lhs: SwapToken, rhs: SwapToken) -> Bool in
            if preferOrder[lhs.token.symbol] != nil || preferOrder[rhs.token.symbol] != nil {
                return (preferOrder[lhs.token.symbol] ?? 3) < (preferOrder[rhs.token.symbol] ?? 3)
            } else if sortByName {
                return lhs.token.name < rhs.token.name
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
