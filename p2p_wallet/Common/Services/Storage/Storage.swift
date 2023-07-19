import Foundation
import KeychainSwift
import SolanaSwift

protocol StorageType {}

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

protocol PincodeSeedPhrasesStorage: PincodeStorageType {
    func save(_ pinCode: String)
}
