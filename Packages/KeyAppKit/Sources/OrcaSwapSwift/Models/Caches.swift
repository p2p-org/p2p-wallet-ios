import Foundation
import SolanaSwift

actor BalancesCache {
    var balancesCache = [String: TokenAccountBalance]()

    func getTokenABalance(pool: Pool) -> TokenAccountBalance? {
        pool.tokenABalance ?? balancesCache[pool.tokenAccountA]
    }

    func getTokenBBalance(pool: Pool) -> TokenAccountBalance? {
        pool.tokenBBalance ?? balancesCache[pool.tokenAccountB]
    }

    func save(key: String, value: TokenAccountBalance) {
        balancesCache[key] = value
    }
}

actor MinRentCache {
    var minRentCache = [String: UInt64]()

    func getTokenABalance(pool: Pool) -> UInt64? {
        pool.tokenAMinimumBalanceForRentExemption ?? minRentCache[pool.tokenAccountA]
    }

    func getTokenBBalance(pool: Pool) -> UInt64? {
        pool.tokenBMinimumBalanceForRentExemption ?? minRentCache[pool.tokenAccountB]
    }

    func save(key: String, value: UInt64) {
        minRentCache[key] = value
    }
}
