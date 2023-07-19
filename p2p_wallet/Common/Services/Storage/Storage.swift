//
//  KeychainStorage.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
import KeychainSwift
import SolanaSwift

protocol StorageType {}

protocol ICloudStorageType: AnyObject, StorageType {
    func saveToICloud(account: RawAccount) -> Bool
    func accountFromICloud() -> [RawAccount]?
}

protocol NameStorageType: StorageType {
    func save(name: String)
    func getName() -> String?
}

protocol PincodeStorageType {
    func saveAttempt(_ attempt: Int)
    var attempt: Int? { get }
    func save(_ pinCode: String)
    var pinCode: String? { get }
}

protocol AccountStorageType: SolanaAccountStorage {
    var ethAddress: String? { get }

    func reloadSolanaAccount() async throws
    func save(phrases: [String]) throws
    func save(derivableType: DerivablePath.DerivableType) throws
    func save(walletIndex: Int) throws
    func save(ethAddress: String) throws

    func clearAccount()
}

protocol PincodeSeedPhrasesStorage: PincodeStorageType {
    var phrases: [String]? { get }
    func save(_ pinCode: String)
}
