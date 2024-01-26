import Foundation

/// Repository that is only responsible for fetching list of items
public protocol ListProvider {
    /// ListItemType to be fetched
    associatedtype ItemType: Hashable & Identifiable
    /// Indicate if should fetching item
    func shouldFetch() -> Bool
    /// Fetch list of item from outside
    func fetch() async throws -> [ItemType]
}

public extension ListProvider {
    func shouldFetch() -> Bool {
        true
    }
}
