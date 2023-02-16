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
    ListMappingStrategy: MappingStrategy
>: ListViewModel<Repository, ListMappingStrategy> where ListMappingStrategy.ItemType == Repository.ItemType {
    @Published private var sections: [any ListSection]?
    
}
