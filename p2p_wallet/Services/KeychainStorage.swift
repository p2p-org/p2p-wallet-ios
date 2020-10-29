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
    let keychain = KeychainSwift()
    
    func save(_ account: SolanaSDK.Account) throws {
        let data = try JSONEncoder().encode(account)
        keychain.set(data, forKey: tokenKey)
    }
    
    var account: SolanaSDK.Account? {
        guard let data = keychain.getData(tokenKey) else {return nil}
        return try? JSONDecoder().decode(SolanaSDK.Account.self, from: data)
    }
    
    func clear() {
        keychain.clear()
    }
}

struct APIManager {
    static let keychainStorage = KeychainStorage()
    static let shared = SolanaSDK(accountStorage: keychainStorage)
}
