import Foundation

// MARK: - StrigaRegistrationAlertLoggerMessage

struct StrigaRegistrationAlertLoggerMessage: Codable {
    let userPubkey, platform, appVersion, timestamp: String
    let error: StrigaRegistrationError
    
    enum CodingKeys: String, CodingKey {
        case userPubkey = "user_pubkey"
        case platform
        case appVersion = "app_version"
        case timestamp, error
    }
}

// MARK: - StrigaRegistrationError

struct StrigaRegistrationError: Codable {
    let source, kycSDKState, error: String
    
    enum CodingKeys: String, CodingKey {
        case source
        case kycSDKState = "kyc_sdk_state"
        case error
    }
}
