import Foundation

/// The protocol for caching username
public protocol NameServiceCacheType {
    func save(_ name: String?, for owner: String)
    func getName(for owner: String) -> NameServiceSearchResult?
}

public enum NameServiceSearchResult {
    case notRegisteredYet
    case registered(String)

    var name: String? {
        switch self {
        case .notRegisteredYet:
            return nil
        case let .registered(string):
            return string
        }
    }
}
