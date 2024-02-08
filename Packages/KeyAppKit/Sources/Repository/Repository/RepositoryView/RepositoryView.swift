import Foundation
import SwiftUI

/// Reusable view for a repository
public struct RepositoryView<
    P: Provider,
    R: Repository<P>,
    LoadingView: View,
    ErrorView: View,
    LoadedView: View
>: View {
    // MARK: - Properties

    /// ViewModel that handle data flow
    @ObservedObject var repository: R

    /// View to handle state when repository is loading, for example ProgressView or Skeleton
    let loadingView: (P.ItemType?) -> LoadingView

    /// View to handle state when an error occurred
    let errorView: (Error, P.ItemType?) -> ErrorView

    /// View to handle state when repository is loaded
    let content: (P.ItemType?) -> LoadedView

    // MARK: - Initializer

    /// RepositoryView's initializer
    /// - Parameters:
    ///   - repository: Repository to handle data flow
    ///   - loadingView: View to handle state when repository is loading, for example ProgressView or Skeleton
    ///   - errorView: View to handle state when an error occurred
    ///   - loadedView: View to handle state when repository is loaded
    public init(
        repository: R,
        @ViewBuilder loadingView: @escaping (P.ItemType?) -> LoadingView,
        @ViewBuilder errorView: @escaping (Error, P.ItemType?) -> ErrorView,
        @ViewBuilder content: @escaping (P.ItemType?) -> LoadedView
    ) {
        self.repository = repository
        self.loadingView = loadingView
        self.errorView = errorView
        self.content = content
    }

    // MARK: - Body

    public var body: some View {
        switch repository.state {
        case .initialized:
            loadingView(nil)
        case .loading:
            loadingView(repository.data)
        case .loaded:
            content(repository.data)
        case .error:
            if let error = repository.error {
                errorView(error, repository.data)
            }
        }
    }
}
