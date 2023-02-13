import Foundation

/// Loading state for a specific time-consuming operation
enum LoadingState {
    /// Nothing loaded
    case initializing
    /// Data is loading
    case fetching
    /// Data is ready to use
    case ready
    /// Error
    case error
}
