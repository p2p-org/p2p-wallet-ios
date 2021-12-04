//
//  KeychainStorage.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
import KeychainSwift
import SolanaSwift

protocol ICloudStorageType: AnyObject {
    func saveToICloud(account: Account) -> Bool
    func accountFromICloud() -> [Account]?
    var didBackupUsingIcloud: Bool {get}
}

protocol NameStorageType {
    func save(name: String)
    func getName() -> String?
}

protocol PincodeStorageType {
    func save(_ pinCode: String)
    var pinCode: String? {get}
}

protocol AccountStorageType: SolanaSDKAccountStorage {
    var phrases: [String]? {get}
    func getDerivablePath() -> SolanaSDK.DerivablePath?
    
    func save(phrases: [String]) throws
    func save(derivableType: SolanaSDK.DerivablePath.DerivableType) throws
    func save(walletIndex: Int) throws
    func clearAccount()
}

protocol PincodeSeedPhrasesStorage: PincodeStorageType {
    var phrases: [String]? {get}
    func save(_ pinCode: String)
}

class KeychainStorage {
    // MARK: - Constants
    private let pincodeKey: String
    private let phrasesKey: String
    private let derivableTypeKey: String
    private let walletIndexKey: String
    private let nameKey: String
    
    private let iCloudAccountsKey = "Keychain.Accounts"
    
    // MARK: - Properties
    private var _account: SolanaSDK.Account?
    
    // MARK: - Services
    private let keychain: KeychainSwift = {
        let kc = KeychainSwift()
        kc.synchronizable = true
        return kc
    }()
    
    // MARK: - Initializers
    init() {
        if let nameKey = Defaults.keychainNameKey {
            self.nameKey = nameKey
        } else {
            self.nameKey = UUID().uuidString
            Defaults.keychainNameKey = nameKey
        }
        
        if let pincodeKey = Defaults.keychainPincodeKey,
           let phrasesKey = Defaults.keychainPhrasesKey,
           let derivableTypeKey = Defaults.keychainDerivableTypeKey,
           let walletIndexKey = Defaults.keychainWalletIndexKey {
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

extension KeychainStorage: ICloudStorageType {
    func saveToICloud(account: Account) -> Bool {
        var accountsToSave = [account]
        
        if var currentAccounts = accountFromICloud() {
            // if account exists
            if let index = currentAccounts.firstIndex(where: { $0.phrase == account.phrase }) {
                currentAccounts[index] = account
            }
            // new account
            else {
                currentAccounts.append(account)
            }
            accountsToSave = currentAccounts
        }
        
        // save
        if let data = try? JSONEncoder().encode(accountsToSave) {
            return keychain.set(data, forKey: iCloudAccountsKey, withAccess: .accessibleAfterFirstUnlock)
        }
        return false
    }
    
    func accountFromICloud() -> [Account]? {
        guard let data = keychain.getData(iCloudAccountsKey) else { return nil }
        return try? JSONDecoder().decode([Account].self, from: data)
    }
    
    var didBackupUsingIcloud: Bool {
        guard let phrases = account?.phrase.joined(separator: " ") else { return false }
        return accountFromICloud()?.contains(where: { $0.phrase == phrases }) == true
    }
}

extension KeychainStorage: NameStorageType {
    func save(name: String) {
        keychain.set(name, forKey: nameKey)
        saveNameToICloudIfAccountSaved()
    }
    
    func getName() -> String? {
        keychain.get(nameKey)
    }
    
    private func saveNameToICloudIfAccountSaved() {
        if let account = accountFromICloud()?.first(where: { $0.phrase.components(separatedBy: " ") == phrases }) {
            let account = Account(
                name: getName(),
                phrase: account.phrase,
                derivablePath: account.derivablePath
            )
            _ = saveToICloud(account: account)
        }
    }
}

extension KeychainStorage: AccountStorageType {
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
    
    var phrases: [String]? {
        account?.phrase
    }
    
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
            else { return nil }
        
        let walletIndexRaw = keychain.get(walletIndexKey)
        let walletIndex = Int(walletIndexRaw ?? "0")
        
        return .init(type: derivableType, walletIndex: walletIndex ?? 0)
    }
    
    func clearAccount() {
        removeCurrentAccount()
    }
    
    private func removeCurrentAccount() {
        keychain.delete(pincodeKey)
        keychain.delete(phrasesKey)
        keychain.delete(derivableTypeKey)
        keychain.delete(walletIndexKey)
        keychain.delete(nameKey)
        
        removeAccountCache()
    }
    
    private func removeAccountCache() {
        _account = nil
    }
}

extension KeychainStorage: PincodeStorageType {
    func save(_ pinCode: String) {
        keychain.set(pinCode, forKey: pincodeKey)
    }
    
    var pinCode: String? {
        keychain.get(pincodeKey)
    }
}

extension KeychainStorage: PincodeSeedPhrasesStorage {}
