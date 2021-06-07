//
//  KeychainStorage.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
import KeychainSwift
import RxSwift

class KeychainAccountStorage: SolanaSDKAccountStorage {
    // MARK: - Constants
    private let phrasesKey = "Keychain.Phrases"
    private let derivableType = "Keychain.DerivableType"
    private let selectedWalletIndex = "Keychain.SelectedWalletIndex"
    
    private let pincodeKey = "Keychain.Pincode"
        
    private let keychain = KeychainSwift()
    private let iCloudStore = NSUbiquitousKeyValueStore()
    
    private var cachedAccount: SolanaSDK.Account?
    
    // MARK: - SolanaSDKAccountStorage
    func save(seedPhrases: [String]) throws {
        keychain.set(seedPhrases.joined(separator: " "), forKey: phrasesKey)
        cachedAccount = nil
    }
    
    func save(derivableType: SolanaSDK.DerivablePath.DerivableType) throws {
        keychain.set(derivableType.rawValue, forKey: self.derivableType)
        cachedAccount = nil
    }
    
    func save(selectedWalletIndex: Int) throws {
        keychain.set("\(selectedWalletIndex)", forKey: self.selectedWalletIndex)
        cachedAccount = nil
    }
    
    func getCurrentAccount() -> Single<SolanaSDK.Account?> {
        Single<SolanaSDK.Account?>.create {observer in
            if let account = self.cachedAccount {
                observer(.success(account))
            } else if let seedPhrases = self.keychain.get(self.phrasesKey)?.components(separatedBy: " "),
                      let derivableTypeRaw = self.keychain.get(self.derivableType),
                      let derivableType = SolanaSDK.DerivablePath.DerivableType(rawValue: derivableTypeRaw),
                      let selectedWalletIndexRaw = self.keychain.get(self.selectedWalletIndex),
                      let selectedWalletIndex = Int(selectedWalletIndexRaw)
            {
                DispatchQueue.global(qos: .userInteractive).async {
                    let account = try? SolanaSDK.Account(phrase: seedPhrases, network: Defaults.apiEndPoint.network, derivablePath: .init(type: derivableType, walletIndex: selectedWalletIndex))
                    observer(.success(account))
                }
            } else {
                observer(.success(nil))
            }
            
            return Disposables.create()
        }
            .do(onSuccess: { [weak self] account in
                self?.cachedAccount = account
            })
            .observe(on: MainScheduler.instance)
    }
    
    func clear() {
        cachedAccount = nil
        keychain.clear()
    }
    
    // MARK: - Pincode
    func save(_ pinCode: String) {
        keychain.set(pinCode, forKey: pincodeKey)
    }
    
    var pinCode: String? {
        keychain.get(pincodeKey)
    }
    
    // MARK: - iCloud
    var didBackupUsingIcloud: Bool {
        phrasesFromICloud() == keychain.get(phrasesKey)
    }
    
    func saveICloud(phrases: String) {
        iCloudStore.set(phrases, forKey: phrasesKey)
    }
    
    func phrasesFromICloud() -> String? {
        iCloudStore.string(forKey: phrasesKey)
    }
}
