import Foundation

enum BankTransferError: Error {
    case invalidKeyPair
    case missingUserId
    case missingMetadata
}
