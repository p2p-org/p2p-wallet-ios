import Foundation
import SolanaSwift

extension DerivablePath {
    var title: String {
        var title = rawValue
        switch type {
        case .deprecated:
            title += " (\(L10n.deprecated))"
        case .bip44Change:
            title += " (\(L10n.default))"
        default:
            break
        }
        return title
    }
}
