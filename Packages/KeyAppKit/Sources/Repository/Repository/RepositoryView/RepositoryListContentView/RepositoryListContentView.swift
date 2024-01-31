import Foundation
import SwiftUI

/// Reusable list view
public struct RepositoryListContentView<
    Provider: ListProvider,
    Repository: ListRepository<Provider>,
    EmptyLoadingView: View,
    EmptyErrorView: View,
    EmptyLoadedView: View,
    ItemView: View,
    LoadMoreView: View
>: View {
    // MARK: - Properties

    /// ViewModel that handle data flow
    @ObservedObject var repository: Repository

    /// Map result
    let map: ([Provider.ItemType]) -> [Provider.ItemType]

    /// View to handle state when list is empty and is loading, for example ProgressView or Skeleton
    let emptyLoadingView: () -> EmptyLoadingView

    /// View to handle state when list is empty and error occurred at the first time loading
    let emptyErrorView: (Error) -> EmptyErrorView

    /// View to handle state when list is loaded and have no data
    let emptyLoadedView: () -> EmptyLoadedView

    /// View of an section of the list
    let itemView: (Provider.ItemType?) -> ItemView

    /// View showing at the bottom of the list
    let loadMoreView: (ListLoadingState.LoadMoreStatus) -> LoadMoreView

    // MARK: - Initializer

    /// PaginatedListView's initializer
    /// - Parameters:
    ///   - viewModel: ViewModel to handle data flow
    ///   - presentationStyle: Presenation type of the list
    ///   - emptyLoadingView: View when list is empty and is loading (ProgressView or Skeleton)
    ///   - emptyErrorView: View when list is empty and error occured
    ///   - emptyLoadedView: View when list is loaded and have no data
    ///   - contentView: Content view of the list
    ///   - loadMoreView: View showing at the bottom of the list (ex: load more)
    public init(
        repository: Repository,
        map: @escaping (([Provider.ItemType]) -> [Provider.ItemType]) = { $0 },
        @ViewBuilder emptyLoadingView: @escaping () -> EmptyLoadingView,
        @ViewBuilder emptyErrorView: @escaping (Error) -> EmptyErrorView = { error in
            Text(String(reflecting: error)).foregroundStyle(Color.red)
        },
        @ViewBuilder emptyLoadedView: @escaping () -> EmptyLoadedView,
        @ViewBuilder itemView: @escaping (Provider.ItemType?) -> ItemView,
        @ViewBuilder loadMoreView: @escaping (ListLoadingState.LoadMoreStatus) -> LoadMoreView = { _ in EmptyView() }
    ) {
        self.repository = repository
        self.map = map
        self.emptyLoadingView = emptyLoadingView
        self.emptyErrorView = emptyErrorView
        self.emptyLoadedView = emptyLoadedView
        self.itemView = itemView
        self.loadMoreView = loadMoreView
    }

    // MARK: - View Buidler

    /// Body of the view
    public var body: some View {
        switch repository.state {
        case let .empty(status):
            VStack {
                Spacer()

                switch status {
                case .loading:
                    emptyLoadingView()
                case .loaded:
                    emptyLoadedView()
                case let .error(error):
                    emptyErrorView(error)
                }

                Spacer()
            }
        case let .nonEmpty(loadMoreStatus):
            // List of items
            ForEach(map(repository.data)) {
                itemView($0)
            }

            // should fetch new items
            loadMoreView(loadMoreStatus)
        }
    }
}

/// Convenience ListView's initializers
public extension RepositoryListContentView where LoadMoreView == EmptyView {
    /// PaginatedListView's initializer
    /// - Parameters:
    ///   - viewModel: ViewModel to handle data flow
    ///   - emptyBooksLoadingView: View when list is empty and is loading (ProgressView or Skeleton)
    ///   - emptyErrorView: View when list is empty and error occured
    ///   - emptyLoadedView: View when list is loaded and have no data
    ///   - itemView: View of an Item on the list
    ///   - loadMoreView: View showing at the bottom of the list (ex: load more)
    init(
        repository: Repository,
        map: @escaping (([Provider.ItemType]) -> [Provider.ItemType]) = { $0 },
        @ViewBuilder emptyLoadingView: @escaping () -> EmptyLoadingView,
        @ViewBuilder emptyErrorView: @escaping (Error) -> EmptyErrorView,
        @ViewBuilder emptyLoadedView: @escaping () -> EmptyLoadedView,
        @ViewBuilder itemView: @escaping (Provider.ItemType?) -> ItemView
    ) {
        self.init(
            repository: repository,
            map: map,
            emptyLoadingView: emptyLoadingView,
            emptyErrorView: emptyErrorView,
            emptyLoadedView: emptyLoadedView,
            itemView: itemView,
            loadMoreView: { _ in
                EmptyView()
            }
        )
    }
}
