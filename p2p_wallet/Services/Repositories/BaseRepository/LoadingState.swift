import Foundation

/// Loading state for a specific time-consuming operation
enum LoadingState {
    /// Nothing loaded
    case initializing
    /// Data is loading
    case loading
    /// Data is loaded
    case loaded
    /// Error
    case error
}
