import Foundation
import Resolver

protocol SendViaLinkStorage {
    @discardableResult
    func save(seed: String) -> Bool
    @discardableResult
    func remove(seed: String) -> Bool
    func getSeeds() -> [String]
}

final class SendViaLinkStorageImpl: SendViaLinkStorage {
    @Injected private var userWalletManager: UserWalletManager
    
    var userPubkey: String? {
        userWalletManager.wallet?.account.publicKey.base58EncodedString
    }
    
    @discardableResult
    func save(seed: String) -> Bool {
        // get seeds
        var seeds = getSeeds()
        
        // assert that seeds has not already existed
        guard !seeds.contains(seed) else {
            return true
        }
        
        // append seed
        seeds.append(seed)
        
        // save
        return save(seeds: seeds)
    }
    
    func remove(seed: String) -> Bool {
        // get seeds from keychain
        var seeds = getSeeds()
        
        // remove seed
        seeds.removeAll(where: { $0 == seed })
        
        // save
        return save(seeds: seeds)
    }
    
    func getSeeds() -> [String] {
        guard let userPubkey else {
            return []
        }
        return Defaults.sendViaLinkSeeds[userPubkey] ?? []
    }
    
    private func save(seeds: [String]) -> Bool {
        guard let userPubkey else {
            return false
        }
        Defaults.sendViaLinkSeeds[userPubkey] = seeds
        return true
    }
}
