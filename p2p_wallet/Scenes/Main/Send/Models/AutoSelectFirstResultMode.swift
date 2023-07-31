import Foundation

enum AutoSelectTheOnlyOneResultMode {
    case enabled(delay: UInt64)

    var isEnabled: Bool {
        switch self {
        case .enabled: return true
        default: return false
        }
    }

    var delay: UInt64? {
        switch self {
        case let .enabled(delay): return delay
        default: return nil
        }
    }
}
