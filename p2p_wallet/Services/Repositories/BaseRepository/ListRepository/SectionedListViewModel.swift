import Foundation
import Combine

protocol ListSection: Hashable {
    associatedtype ItemType: ListItem
    var id: UUID { get }
    var items: [ItemType] { get }
    var userInfo: AnyHashable { get }
}

@MainActor
class SectionedListViewModel<
    Repository: AnyListRepository,
    MappingStrategy: ListMappingStrategy
>: ListViewModel<Repository, MappingStrategy> where MappingStrategy.Sequence == Repository.ItemType {
    @Published private var sections: [any ListSection]?
    
}
