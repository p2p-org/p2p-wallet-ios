actor DerivableAccountsCache {
    var balanceCache = [String: Double]() // PublicKey: Balance
    var solPriceCache: Double?

    func save(account: String, amount: Double) {
        balanceCache[account] = amount
    }

    func save(solPrice: Double) {
        solPriceCache = solPrice
    }
}
