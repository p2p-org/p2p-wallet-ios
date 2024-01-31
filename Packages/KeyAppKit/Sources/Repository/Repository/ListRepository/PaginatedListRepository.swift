import Foundation

/// Reusable ViewModel to manage a paginated List of some Kind of item
open class PaginatedListRepository<P: PaginatedListProvider>: ListRepository<P> {
    // MARK: - Properties

    /// Result count of first request, can be use to keeps first record on refreshing
    @MainActor private var firstPageCount: Int?

    // MARK: - Actions

    /// Erase data and reset repository to its initial state
    @MainActor
    override open func flush() {
        provider.paginationStrategy.resetPagination()
        super.flush()
    }

    /// Refresh data
    override open func refresh() async {
        // keep first page as placeholder
        await MainActor.run {
            data = Array(data.prefix(firstPageCount ?? 0))
            isLoading = false
            error = nil
        }

        // reset pagination
        await provider.paginationStrategy.resetPagination()

        // request to update first page
        let firstPageResult = await request()
        switch firstPageResult {
        case let .success(firstPage):
            // replace first page
            await MainActor.run {
                data = firstPage
                isLoading = false
                error = nil
            }

        case let .failure(failure):
            guard !(failure is CancellationError) else {
                return
            }

            await MainActor.run {
                data = []
                isLoading = false
                error = failure
            }
        }
    }

    /// Handle new data that just received
    /// - Parameter newData: the new data received
    @MainActor
    override open func handleNewData(_ newData: [ItemType]) {
        // cache first page count
        if firstPageCount == nil {
            firstPageCount = newData.count
        }

        // check if last page loaded
        provider.paginationStrategy.checkIfLastPageLoaded(lastSnapshot: newData)

        // move to next page
        provider.paginationStrategy.moveToNextPage()

        // append data that is currently not existed in current data array
        // keep objects in data unique by removing item with duplicated id
        data = (data + newData)
            .reduce([]) { result, current -> [ItemType] in
                // keep last updated item by default
                if result.contains(where: { $0.id == current.id }) {
                    return result
                }

                // append new
                else {
                    return result + [current]
                }
            }
        super.handleNewData(data)
    }

    /// Fetch next records if pagination is enabled
    open func fetchNext() async {
        // call request
        await request()
    }

    /// List loading state
    @MainActor
    override open var state: ListLoadingState {
        let state = super.state

        switch state {
        case .nonEmpty:
            if provider.shouldFetch() {
                // Error at the end of the list
                if let error {
                    return .nonEmpty(loadMoreStatus: .error(error))
                }

                // Loading at the end of the list
                else {
                    return .nonEmpty(loadMoreStatus: .loading)
                }
            } else {
                return .nonEmpty(loadMoreStatus: .reachedEndOfList)
            }
        default:
            return state
        }
    }

//    func updateFirstPage(onSuccessFilterNewData: (([ItemType]) -> [ItemType])? = nil) {
//        let originalOffset = offset
//        offset = 0
//
//        task?.cancel()
//
//        task = Task {
//            let onSuccess = onSuccessFilterNewData ?? {[weak self] newData in
//                newData.filter {!(self?.data.contains($0) == true)}
//            }
//            var data = self.data
//            let newData = try await self.createRequest()
//            data = onSuccess(newData) + data
//            self.overrideData(by: data)
//        }
//
//        offset = originalOffset
//    }
}
