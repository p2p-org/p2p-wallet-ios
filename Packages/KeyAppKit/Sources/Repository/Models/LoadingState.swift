import Foundation

/// Loading state for a specific time-consuming operation
public enum LoadingState {
    /// Nothing loaded
    case initialized
    /// Data is loading
    case loading
    /// Data is loaded
    case loaded
    /// Error
    case error
}

public enum ListLoadingState {
    public enum Status {
        case loading
        case loaded
        case error(Error)
    }

    public enum LoadMoreStatus {
        case loading
        case reachedEndOfList
        case error(Error)
    }

    case empty(Status)
    case nonEmpty(loadMoreStatus: LoadMoreStatus)

    public var isEmpty: Bool {
        switch self {
        case .empty:
            return true
        default:
            return false
        }
    }
}
