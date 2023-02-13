import Resolver

final class ChooseSwapTokenService: ChooseItemService {

    private let swapTokens: [SwapToken]
    init(swapTokens: [SwapToken]) {
        self.swapTokens = swapTokens
    }

    func fetchItems() async throws -> [ChooseItemListData] {
        let firstSection = swapTokens.filter({ $0.userWallet != nil })
        let secondSection = swapTokens.filter({ $0.userWallet == nil })
        return [ChooseItemListData(id: .init(), items: firstSection), ChooseItemListData(id: .init(), items: secondSection)]
    }

    func filterAndSort(items: [ChooseItemListData], by keyword: String) -> [ChooseItemListData] {
        items.map { section in
            return ChooseItemListData(id: .init(), items: (section.items as! [SwapToken]).filteredAndSorted(byKeyword: keyword))
        }
    }
}

extension Array where Element == SwapToken {
    func filteredAndSorted(byKeyword keyword: String = "") -> Self {
        var wallets = self

        if !keyword.isEmpty {
            let keyword = keyword.lowercased()
            wallets = wallets
                .filter { wallet in
                    // Filter only wallets which name starts with keyword
                    return wallet.jupiterToken.name.lowercased().starts(with: keyword)
                    || wallet.jupiterToken.name.lowercased().split(separator: " ").map { $0.starts(with: keyword) }.contains(true)
                }
        }

        let preferOrder: [String: Int] = ["USDC": 1, "USDT": 2]
        let sortedWallets = wallets
            .sorted { (lhs: SwapToken, rhs: SwapToken) -> Bool in
                if preferOrder[lhs.jupiterToken.symbol] != nil || preferOrder[rhs.jupiterToken.symbol] != nil {
                    return (preferOrder[lhs.jupiterToken.symbol] ?? 3) < (preferOrder[rhs.jupiterToken.symbol] ?? 3)
                } else {
                    return lhs.userWallet?.amountInCurrentFiat > rhs.userWallet?.amountInCurrentFiat
                }
            }
        return sortedWallets
    }
}
