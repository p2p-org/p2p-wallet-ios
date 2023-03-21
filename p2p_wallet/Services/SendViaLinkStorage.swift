import Foundation
import Resolver
import SolanaSwift
import SwiftyUserDefaults

struct SendViaLinkTransactionInfo: Codable {
    let amount: Double
    let amountInFiat: Double
    let token: Token
    let seed: String
}

protocol SendViaLinkStorage {
    @discardableResult
    func save(transaction: SendViaLinkTransactionInfo) -> Bool
    @discardableResult
    func remove(seed: String) -> Bool
    func getTransactions() -> [SendViaLinkTransactionInfo]
}

final class SendViaLinkStorageImpl: SendViaLinkStorage {
    @Injected private var userWalletManager: UserWalletManager
    
    var userPubkey: String? {
        userWalletManager.wallet?.account.publicKey.base58EncodedString
    }
    
    @discardableResult
    func save(transaction: SendViaLinkTransactionInfo) -> Bool {
        // get seeds
        var seeds = getTransactions()
        
        // assert that seeds has not already existed
        guard !seeds.contains(where: { $0.seed == transaction.seed }) else {
            return true
        }
        
        // append seed
        seeds.append(transaction)
        
        // save
        return save(seeds: seeds)
    }
    
    func remove(seed: String) -> Bool {
        // get seeds from keychain
        var seeds = getTransactions()
        
        // remove seed
        seeds.removeAll(where: { $0.seed == seed })
        
        // save
        return save(seeds: seeds)
    }
    
    func getTransactions() -> [SendViaLinkTransactionInfo] {
        guard let userPubkey else {
            return []
        }
        return Defaults.sendViaLinkTransactions[userPubkey] ?? []
    }
    
    private func save(seeds: [SendViaLinkTransactionInfo]) -> Bool {
        guard let userPubkey else {
            return false
        }
        Defaults.sendViaLinkTransactions[userPubkey] = seeds
        return true
    }
}
