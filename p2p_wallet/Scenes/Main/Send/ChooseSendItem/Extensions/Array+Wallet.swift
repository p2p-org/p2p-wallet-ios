import SolanaSwift

extension Array where Element == Wallet {
    func sorted() -> Self {
        let preferOrder: [String: Int] = ["USDC": 1, "USDT": 2]
        return self
            .sorted { (lhs: Wallet, rhs: Wallet) -> Bool in
                if preferOrder[lhs.token.symbol] != nil || preferOrder[rhs.token.symbol] != nil {
                    return (preferOrder[lhs.token.symbol] ?? 3) < (preferOrder[rhs.token.symbol] ?? 3)
                } else {
                    return lhs.amountInCurrentFiat > rhs.amountInCurrentFiat
                }
            }
    }
}
