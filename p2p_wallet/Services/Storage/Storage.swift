//
//  KeychainStorage.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
import KeychainSwift
import RxCocoa
import RxSwift
import SolanaSwift

typealias StorageValueOnChange = (key: String, value: Any?)

protocol StorageType {
    // listens to value changing
    var onValueChange: Signal<StorageValueOnChange> { get }
}

protocol ICloudStorageType: AnyObject, StorageType {
    func saveToICloud(account: RawAccount) -> Bool
    func accountFromICloud() -> [RawAccount]?
    var didBackupUsingIcloud: Bool { get }
}

protocol NameStorageType: StorageType {
    func save(name: String)
    func getName() -> String?
}

protocol PincodeStorageType {
    func save(_ pinCode: String)
    var pinCode: String? { get }
}

protocol AccountStorageType: SolanaAccountStorage {
    func getDerivablePath() -> DerivablePath?

    func save(phrases: [String]) throws
    func save(derivableType: DerivablePath.DerivableType) throws
    func save(walletIndex: Int) throws
    func clearAccount()
}

protocol PincodeSeedPhrasesStorage: PincodeStorageType {
    var phrases: [String]? { get }
    func save(_ pinCode: String)
}
