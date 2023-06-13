import Foundation

public enum BankTransferError: Int, Error {
    case invalidKeyPair
    case missingUserId
    case missingMetadata
    case otpExceededVerification = 30003
    case otpExceededDailyLimit = 31008
}
