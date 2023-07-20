import Foundation
import KeyAppBusiness

public enum WormholeClaimUserActionError: Int, Error {
    public typealias RawValue = Int
    
    public static let domain = "WormholeClaimUserActionConsumer"

    public static let invalidToken = UserActionError(
        domain: domain,
        code: WormholeClaimUserActionError.invalidTokenCode.rawValue,
        reason: "Can not resolve token for new bundle"
    )

    public static let submitError = UserActionError(
        domain: "WormholeClaimUserActionConsumer",
        code: WormholeClaimUserActionError.submitErrorCode.rawValue,
        reason: "Sending Ethereum bundle returns with error"
    )
    
    public static let claimFailure = UserActionError(
        domain: "WormholeClaimUserActionConsumer",
        code: WormholeClaimUserActionError.claimFailureCode.rawValue,
        reason: "Claiming is failed"
    )

    case invalidTokenCode = 1
    case submitErrorCode
    case claimFailureCode
    
    public enum UserInfoKey: String {
        case action
        case token
        case tokenAmount
    }
}
