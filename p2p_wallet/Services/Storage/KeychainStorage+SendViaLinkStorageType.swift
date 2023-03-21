import Foundation
import KeychainSwift

extension KeychainStorage: SendViaLinkStorageType {
    @discardableResult
    func save(seed: String) -> Bool {
        // get seeds from keychain
        var seeds = getSeeds()
        
        // assert that seeds has not already existed
        guard !seeds.contains(seed) else {
            return true
        }
        
        // append seed
        seeds.append(seed)
        
        // save
        return saveToKeychain(seeds: seeds)
    }
    
    func remove(seed: String) -> Bool {
        // get seeds from keychain
        var seeds = getSeeds()
        
        // remove seed
        seeds.removeAll(where: { $0 == seed })
        
        // save to keychain
        return saveToKeychain(seeds: seeds)
    }
    
    func getSeeds() -> [String] {
        // get icloud keychain
        let icloudKeychain = KeychainSwift()
        icloudKeychain.synchronizable = true
        
        // get current seeds
        var seeds = [String]()
        if let data = icloudKeychain.getData(iCloudSendViaLinkSeedsKey),
           let seedsFromICloud = try? JSONDecoder().decode([String].self, from: data)
        {
            seeds = seedsFromICloud
        }
        return seeds
    }
    
    private func saveToKeychain(seeds: [String]) -> Bool {
        if let data = try? JSONEncoder().encode(seeds) {
            // get icloud keychain
            let icloudKeychain = KeychainSwift()
            icloudKeychain.synchronizable = true
            
            icloudKeychain.set(data, forKey: iCloudAccountsKey, withAccess: .accessibleAfterFirstUnlock)
            return true
        }
        return false
    }
}
