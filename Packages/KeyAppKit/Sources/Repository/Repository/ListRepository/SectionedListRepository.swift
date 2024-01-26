import Combine
import Foundation

/// Section of a list
protocol ListSection: Hashable {
    /// Type of item in the section
    associatedtype ItemType: Hashable & Identifiable
    var id: String { get }
    /// List of items in section
    var items: [ItemType] { get }
    /// state of the section
    var loadingState: LoadingState { get }
    /// error of the section
    var error: String? { get } // TODO: - Error type is not Hashable
}

/// Define if a viewModel can be convertible to sections
protocol SectionsConvertibleListRepository: ObservableObject {
    /// Type of item in the section
    associatedtype ItemType: Hashable & Identifiable
    associatedtype Section: ListSection
    /// Map data to sections
    var sections: [Section] { get }
    /// Erase all data
    func flush()
    /// Reload data
    func reload() async throws
    /// Refresh
    func refresh() async throws
}

/// Reusable list view model of a sectioned list
// @MainActor
// class SectionedListViewModel: ObservableObject {
//
//    // MARK: - Properties
//
//    /// Combine subscriptions
//    private var subscriptions = Set<AnyCancellable>()
//
//    /// List view models to handle different type of data, each viewmodel represent one or more sections
//    private let listViewModels: [any SectionsConvertibleListViewModel]
//
//    /// Initial data for initializing state
//    private let initialData: [any ListSection]
//
//    /// Sections in list
//    @Published var sections: [any ListSection] = []
//
//    // MARK: - Initializer
//
//    /// SectionedListViewModel initializer
//    /// - Parameters:
//    ///   - initialData: initial data for begining state
//    ///   - listViewModels: listViewModels to handle data
//    init(
//        initialData: [any ListSection] = [],
//        listViewModels: [any SectionsConvertibleListViewModel]
//    ) {
//        self.initialData = initialData
//        self.listViewModels = listViewModels
//
//        sections = initialData
//        bind()
//    }
//
//    // MARK: - Binding
//
//    private func bind() {
//        // assertion
//        guard !listViewModels.isEmpty else { return }
//
//        // combine data
//        var publisher = listViewModels.first!
//            .sectionsPublisher
//            .eraseToAnyPublisher()
//
//        for viewModel in listViewModels {
//            publisher = publisher
//                .combineLatest(viewModel.sectionsPublisher)
//                .map { $0 + $1 }
//                .eraseToAnyPublisher()
//        }
//
//        publisher
//            .receive(on: DispatchQueue.main)
//            .assign(to: \.sections, on: self)
//            .store(in: &subscriptions)
//    }
//
//    // MARK: - Actions
//
//    /// Erase data and reset repository to its initial state
//    func flush() {
//        // flush viewModels data
//        for viewModel in listViewModels {
//            viewModel.flush()
//        }
//
//        // flush this viewModel
//        sections = initialData
//    }
//
//    /// Erase and reload all data
//    func reload() async throws {
//        // request in parallel
//        try await withThrowingTaskGroup(of: Void.self) { group in
//            for viewModel in listViewModels {
//                group.addTask {
//                    try await viewModel.reload()
//                }
//            }
//
//            for try await _ in group {}
//        }
//    }
//
//    /// Refresh data without erasing current data
//    func refresh() async throws {
//        // request in parallel
//        try await withThrowingTaskGroup(of: Void.self) { group in
//            for viewModel in listViewModels {
//                group.addTask {
//                    try await viewModel.refresh()
//                }
//            }
//
//            for try await _ in group {}
//        }
//    }
// }
