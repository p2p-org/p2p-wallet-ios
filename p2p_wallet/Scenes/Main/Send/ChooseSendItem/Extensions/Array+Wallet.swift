import SolanaSwift

extension Array where Element == Wallet {
    func filteredAndSorted(byKeyword keyword: String = "") -> Self {
        var wallets = self

        if !keyword.isEmpty {
            let keyword = keyword.lowercased()
            wallets = wallets.filter {  $0.matches(keyword: keyword) }
        }

        let preferOrder: [String: Int] = ["USDC": 1, "USDT": 2]
        let sortedWallets = wallets
            .sorted { (lhs: Wallet, rhs: Wallet) -> Bool in
                if preferOrder[lhs.token.symbol] != nil || preferOrder[rhs.token.symbol] != nil {
                    return (preferOrder[lhs.token.symbol] ?? 3) < (preferOrder[rhs.token.symbol] ?? 3)
                } else {
                    return lhs.amountInCurrentFiat > rhs.amountInCurrentFiat
                }
            }
        return sortedWallets
    }
}
