import Foundation
import KeyAppNetworking

public enum StrigaEndpoint {
    case verifyMobileNumber(authHeader: AuthHeader, userId: String, verificationCode: String)
    case getUserDetails(authHeader: AuthHeader, userId: String)
    case createUser(authHeader: AuthHeader, model: StrigaCreateUserRequest)
    case resendSMS(authHeader: AuthHeader, userId: String)
    
    case kycGetToken(authHeader: AuthHeader, userId: String)
}

// MARK: - HTTPEndpoint

extension StrigaEndpoint: HTTPEndpoint {
    public var baseURL: String {
        "https://\(urlEnvironment)/api/\(version)/user"
    }
    
    public var header: [String: String] {
        [
            "Content-Type": "application/json",
            "User-PublicKey": authHeader.pubKey,
            "Signed-Message": authHeader.signedMessage
        ]
    }
    
    public var path: String {
        switch self {
        case .verifyMobileNumber:
            return "/verify-mobile"
        case let .getUserDetails(_, userId):
            return "/" + userId
        case .createUser:
            return "/create"
        case .resendSMS:
            return "/resend-sms"
        case .kycGetToken:
            return "/kyc/start"
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .verifyMobileNumber, .createUser, .resendSMS, .kycGetToken:
            return .post
        case .getUserDetails:
            return .get
        }
    }

    public var body: String? {
        switch self {
        case let .verifyMobileNumber(_, userId, verificationCode):
            return ["userId": userId, "verificationCode": verificationCode].encoded
        case .getUserDetails:
            return nil
        case let .createUser(_, model):
            return model.encoded
        case let .resendSMS(_, userId):
            return ["userId": userId].encoded
        case let .kycGetToken(_, userId):
            return ["userId": userId].encoded
        }
    }
}

// MARK: - URL parts

private extension StrigaEndpoint {
    var urlEnvironment: String {
        switch self {
        case .verifyMobileNumber, .createUser, .getUserDetails, .resendSMS:
            return "payment.keyapp.org/striga"
        case .kycGetToken:
            return "payment.key.app/striga"
        }
    }
    
    var version: String {
        "v1"
    }
    
    var authHeader: AuthHeader {
        switch self {
        case let .verifyMobileNumber(authHeader, _, _):
            return authHeader
        case let .getUserDetails(authHeader, _):
            return authHeader
        case let .createUser(authHeader, _):
            return authHeader
        case let .resendSMS(authHeader, _):
            return authHeader
        case let .kycGetToken(authHeader, _):
            return authHeader
        }
    }
}

// MARK: - Encoding

private extension Encodable {
    /// Encoded string for request as a json string
    var encoded: String? {
        encoded(strategy: .useDefaultKeys)
    }
    
    func encoded(strategy: JSONEncoder.KeyEncodingStrategy) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.keyEncodingStrategy = strategy
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - Auth Header

extension StrigaEndpoint {
    public struct AuthHeader {
        public let pubKey: String
        public let signedMessage: String
    }
}
