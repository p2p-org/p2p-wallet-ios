import Foundation

public enum BankTransferError: Int, Error {
    case invalidKeyPair
    case missingUserId
    case missingMetadata
    case otpExceededVerification = 30003
    case otpExceededDailyLimit = 31008
    case mobileAlreadyExists = 30041
    case mobileAlreadyVerified

    // KYC start
    case kycVerificationInProgress = 30009
    case kycRejectedCantRetry = 30010
    case kycAttemptLimitExceeded = 30011
}
