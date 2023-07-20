import Foundation

enum SocialServiceError: Error {
    case cancelled
    case unknown
    case invalidSocialType
    case tokenIDIsNil
}
