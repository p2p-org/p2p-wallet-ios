import Foundation
import KeyAppBusiness
import Wormhole

public enum WormholeSendUserActionEvent: UserActionEvent {
    case track(WormholeSendStatus)
    case sendFailure(message: String, error: UserActionError)
}
