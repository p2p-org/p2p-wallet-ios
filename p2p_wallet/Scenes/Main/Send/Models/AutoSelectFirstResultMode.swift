import Foundation

enum AutoSelectTheOnlyOneResultMode {
    case disabled
    case enabled(delay: UInt64)
    
    var isEnabled: Bool {
        switch self {
        case .enabled: return true
        default: return false
        }
    }
    
    var delay: UInt64? {
        switch self {
        case .enabled(let delay): return delay
        default: return nil
        }
    }
}
