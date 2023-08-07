import Foundation
import LocalAuthentication

extension LABiometryType {
    var stringValue: String {
        switch self {
        case .touchID:
            return L10n.touchID
        case .faceID:
            return L10n.faceID
        default:
            return ""
        }
    }
}
