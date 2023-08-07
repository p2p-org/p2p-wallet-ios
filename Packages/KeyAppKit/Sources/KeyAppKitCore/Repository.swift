import Foundation

public protocol Repository {
    associatedtype Element: Identifiable

    func get(id: Element.ID) async throws
}
