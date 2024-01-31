enum ReferralBridgeMethod: String {
    case showShareDialog
    case nativeLog
    case signMessage
    case getUserPublicKey
}

enum ReferralBridgeError: String {
    case emptyAddress
    case emptyLog
    case signFailed
    case emptyLink
}
