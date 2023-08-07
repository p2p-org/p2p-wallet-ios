import Foundation
import KeyAppBusiness

public enum WormholeClaimUserActionEvent: UserActionEvent {
    case track(WormholeBundleStatus)

    case claimFailure(bundleID: String, reason: UserActionError)
    case claimInProgress(bundleID: String)

    case refresh
}
