//
//  KeychainStorage.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
import KeychainSwift

protocol ICloudStorageType {
    func saveToICloud(account: Account)
    func accountFromICloud() -> [Account]?
}

class KeychainAccountStorage: SolanaSDKAccountStorage, ICloudStorageType {
    // MARK: - Constants
    private let pincodeKey: String
    private let phrasesKey: String
    private let derivableTypeKey: String
    private let walletIndexKey: String
    
    private let iCloudAccountsKey = "Keychain.Accounts"
    
    // MARK: - Properties
    private var _account: SolanaSDK.Account?
    
    // MARK: - Services
    let keychain: KeychainSwift = {
        let kc = KeychainSwift()
        kc.synchronizable = true
        return kc
    }()
    
    // MARK: - Initializers
    init() {
        if let pincodeKey = Defaults.keychainPincodeKey,
              let phrasesKey = Defaults.keychainPhrasesKey,
              let derivableTypeKey = Defaults.keychainDerivableTypeKey,
              let walletIndexKey = Defaults.keychainWalletIndexKey
        {
            self.pincodeKey = pincodeKey
            self.phrasesKey = phrasesKey
            self.derivableTypeKey = derivableTypeKey
            self.walletIndexKey = walletIndexKey
        } else {
            let pincodeKey = UUID().uuidString
            self.pincodeKey = pincodeKey
            Defaults.keychainPincodeKey = pincodeKey
            
            let phrasesKey = UUID().uuidString
            self.phrasesKey = phrasesKey
            Defaults.keychainPhrasesKey = phrasesKey
            
            let derivableTypeKey = UUID().uuidString
            self.derivableTypeKey = derivableTypeKey
            Defaults.keychainDerivableTypeKey = derivableTypeKey
            
            let walletIndexKey = UUID().uuidString
            self.walletIndexKey = walletIndexKey
            Defaults.keychainWalletIndexKey = walletIndexKey
            
            removeCurrentAccount()
        }
        
        migrate()
    }
    
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
    
    func getDerivablePath() -> SolanaSDK.DerivablePath? {
        guard let derivableTypeRaw = keychain.get(derivableTypeKey),
              let derivableType = SolanaSDK.DerivablePath.DerivableType(rawValue: derivableTypeRaw)
        else {return nil}
        
        let walletIndexRaw = keychain.get(walletIndexKey)
        let walletIndex = Int(walletIndexRaw ?? "0")
        
        return .init(type: derivableType, walletIndex: walletIndex ?? 0)
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
        guard let phrases = account?.phrase.joined(separator: " ") else {return false}
        return accountFromICloud()?.contains(where: {$0.phrase == phrases}) == true
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
    func saveToICloud(account: Account) {
        var accountsToSave = [account]
        
        // if accounts exists
        if var currentAccounts = accountFromICloud() {
            // remove (for overriding)
            currentAccounts.removeAll(where: {$0.phrase == account.phrase})
            
            // add
            currentAccounts.append(account)
            
            accountsToSave = currentAccounts
        }
        
        // save
        if let data = try? JSONEncoder().encode(accountsToSave) {
            keychain.set(data, forKey: iCloudAccountsKey)
        }
    }
    
    func accountFromICloud() -> [Account]? {
        guard let data = keychain.getData(iCloudAccountsKey) else {return nil}
        return try? JSONDecoder().decode([Account].self, from: data)
    }
    
    // MARK: - Clearance
    func clear() {
        removeCurrentAccount()
    }
    
    func removeCurrentAccount() {
        keychain.delete(pincodeKey)
        keychain.delete(phrasesKey)
        keychain.delete(derivableTypeKey)
        keychain.delete(walletIndexKey)
        
        removeAccountCache()
    }
    
    // MARK: - Migration
    func migrate() {
        // migrate iCloud storage from NSUbiquitousKeyValueStore to keychain
        let ubiquitousKeyValueStoreToKeychain = "UbiquitousKeyValueStoreToKeychain"
        if !UserDefaults.standard.bool(forKey: ubiquitousKeyValueStoreToKeychain) {
            let ubiquitousStore = NSUbiquitousKeyValueStore()
            if let data = ubiquitousStore.data(forKey: iCloudAccountsKey) {
                keychain.set(data, forKey: iCloudAccountsKey)
            }
            // mark as completed
            UserDefaults.standard.set(true, forKey: ubiquitousKeyValueStoreToKeychain)
        }
    }
}
