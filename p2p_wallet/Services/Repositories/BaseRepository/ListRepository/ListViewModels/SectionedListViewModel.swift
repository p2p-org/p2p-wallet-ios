import Foundation
import Combine

/// Section of a list
protocol ListSection: Hashable {
    /// Type of item in the section
    associatedtype ItemType: Hashable & Identifiable
    /// Id of section
    var id: UUID { get }
    /// List of items in section
    var items: [ItemType] { get }
    /// Additional userInfo
    var userInfo: AnyHashable? { get }
}

/// Reusable list view model of a sectioned list
@MainActor
class SectionedListViewModel: ObservableObject {
    
    // MARK: - Properties

    /// Sections in list
    @Published private var sections: [any ListSection] = []
    
}
