//
//  KeychainStorage.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
import KeychainSwift

struct KeychainStorage: SolanaSDKAccountStorage {
    let tokenKey = "Keychain.Token"
    let pincodeKey = "Keychain.Pincode"
    let phrasesKey = "Keychain.Phrases"
        
    let keychain = KeychainSwift()
    let iCloudStore = NSUbiquitousKeyValueStore()
    
    static let shared = KeychainStorage()
    private init() {}
    
    // MARK: - Account
    func save(_ account: SolanaSDK.Account) throws {
        let data = try JSONEncoder().encode(account)
        keychain.set(data, forKey: tokenKey)
    }
    
    var account: SolanaSDK.Account? {
        guard let data = keychain.getData(tokenKey) else {return nil}
        return try? JSONDecoder().decode(SolanaSDK.Account.self, from: data)
    }
    
    // MARK: - Pincode
    func save(_ pinCode: String) {
        keychain.set(pinCode, forKey: pincodeKey)
    }
    
    var pinCode: String? {
        keychain.get(pincodeKey)
    }
    
    // MARK: - iCloud
    func saveICloud(phrases: String) {
        iCloudStore.set(phrases, forKey: phrasesKey)
    }
    
    func retrieveAccountFromICloud() throws {
        // retrieve from iCloud
        if let phrases = iCloudStore.string(forKey: phrasesKey) {
            let account = try SolanaSDK.Account(phrase: phrases.components(separatedBy: " "), network: SolanaSDK.network)
            try KeychainStorage.shared.save(account)
        }
    }
    
    // MARK: - Clearance
    func clear() {
        iCloudStore.removeObject(forKey: phrasesKey)
        keychain.clear()
    }
}
