import KeyAppKitCore

extension Array where Element == SolanaAccount {
    func sorted(preferOrderSymbols: [String] = []) -> Self {
        sorted { (lhs: SolanaAccount, rhs: SolanaAccount) -> Bool in
            if preferOrderSymbols.contains(lhs.data.token.symbol) || preferOrderSymbols.contains(rhs.data.token.symbol) {
                // Check if prefered tokens exists
                let lhsIndex = preferOrderSymbols
                    .firstIndex(where: { $0 == lhs.data.token.symbol }) ?? preferOrderSymbols.count
                let rhsIndex = preferOrderSymbols
                    .firstIndex(where: { $0 == rhs.data.token.symbol }) ?? preferOrderSymbols.count
                return lhsIndex < rhsIndex
            } else {
                
                // Otherwise sort by fiat amount
                return (lhs.amountInFiat ?? .zero) > (rhs.amountInFiat ?? .zero)
            }
        }
    }
}
