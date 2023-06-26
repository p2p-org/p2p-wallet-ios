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
