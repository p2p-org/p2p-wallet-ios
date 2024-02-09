enum ReferralBridgeMethod: String {
    case showShareDialog
    case nativeLog
    case signMessage
    case getUserPublicKey
    case openTermsUrl
}

enum ReferralBridgeError: String {
    case emptyAddress
    case emptyLog
    case signFailed
    case emptyLink
}
