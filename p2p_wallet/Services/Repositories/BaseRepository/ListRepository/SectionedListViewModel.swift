import Foundation
import Combine

protocol ListSection: Hashable {
    associatedtype ItemType: Hashable
    var id: UUID { get }
    var items: [ItemType] { get }
    var userInfo: AnyHashable { get }
}

@MainActor
class SectionedListViewModel<Repository: AnyListRepository>: ListViewModel<Repository> {
    @Published private var sections: [any ListSection]?
    
}
