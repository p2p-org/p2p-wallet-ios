import Foundation

/// Supported routes for deep linking
public enum Route: Equatable {
    /// Claim send via link with a seed from url
    case claimSentViaLink(seed: String)
    /// Open survey from intercom
    case intercomSurvey(id: String)
    /// Debug login with url
    case debugLoginWithURL(seedPhrase: String, pincode: String)
}
