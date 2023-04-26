import SolanaSwift

extension Array where Element == Wallet {
    func sorted(preferOrderSymbols: [String] = []) -> Self {
        self
            .sorted { (lhs: Wallet, rhs: Wallet) -> Bool in
                if preferOrderSymbols.contains(lhs.token.symbol) || preferOrderSymbols.contains(rhs.token.symbol) {
                    // Check if prefered tokens exists
                    let lhsIndex = preferOrderSymbols.firstIndex(where: { $0 == lhs.token.symbol }) ?? preferOrderSymbols.count
                    let rhsIndex = preferOrderSymbols.firstIndex(where: { $0 == rhs.token.symbol }) ?? preferOrderSymbols.count
                    return lhsIndex < rhsIndex
                } else {
                    // Otherwise sort by fiat amount
                    return lhs.amountInCurrentFiat > rhs.amountInCurrentFiat
                }
            }
    }
}
