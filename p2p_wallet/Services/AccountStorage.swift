//
//  KeychainStorage.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
import KeychainSwift

class KeychainAccountStorage: SolanaSDKAccountStorage {
    // MARK: - Constants
    private let pincodeKey = "Keychain.Pincode"
    private let phrasesKey = "Keychain.Phrases"
    private let derivableTypeKey = "Keychain.DerivableType"
    private let walletIndexKey = "Keychain.WalletIndexKey"
        
    // MARK: - Properties
    private var _account: SolanaSDK.Account?
    
    // MARK: - Services
    let keychain = KeychainSwift()
    let iCloudStore = NSUbiquitousKeyValueStore()
    
    // MARK: - SolanaSDKAccountStorage
    func save(phrases: [String]) throws {
        keychain.set(phrases.joined(separator: " "), forKey: phrasesKey)
        _account = nil
    }
    
    func save(derivableType: SolanaSDK.DerivablePath.DerivableType) throws {
        keychain.set(derivableType.rawValue, forKey: derivableTypeKey)
        _account = nil
    }
    
    func save(walletIndex: Int) throws {
        keychain.set("\(walletIndex)", forKey: walletIndexKey)
        _account = nil
    }
    
    var account: SolanaSDK.Account? {
        if let account = _account {
            return account
        }
        
        guard let phrases = keychain.get(phrasesKey)?.components(separatedBy: " ")
        else {
            return nil
        }
        let derivableTypeRaw = keychain.get(derivableTypeKey) ?? ""
        let walletIndexRaw = keychain.get(walletIndexKey) ?? ""
        
        let defaultDerivablePath = SolanaSDK.DerivablePath.default
        
        let derivableType = SolanaSDK.DerivablePath.DerivableType(rawValue: derivableTypeRaw) ?? defaultDerivablePath.type
        let walletIndex = Int(walletIndexRaw) ?? defaultDerivablePath.walletIndex
        
        _account = try? SolanaSDK.Account(
            phrase: phrases,
            network: Defaults.apiEndPoint.network,
            derivablePath: .init(type: derivableType, walletIndex: walletIndex)
        )
        
        return _account
    }
    
    func removeAccountCache() {
        _account = nil
    }
    
    // MARK: - Helpers
    var didBackupUsingIcloud: Bool {
        phrasesFromICloud() == account?.phrase.joined(separator: " ")
    }
    
    var phrases: [String]? {
        account?.phrase
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
    
    func phrasesFromICloud() -> String? {
        iCloudStore.string(forKey: phrasesKey)
    }
    
    // MARK: - Clearance
    func clear() {
        keychain.clear()
        removeAccountCache()
    }
}
