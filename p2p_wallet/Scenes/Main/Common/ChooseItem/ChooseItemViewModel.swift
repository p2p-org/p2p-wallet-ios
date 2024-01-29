import Combine
import Resolver
import SolanaSwift
import UIKit

final class ChooseItemViewModel: BaseViewModel, ObservableObject {
    let chooseTokenSubject = PassthroughSubject<any ChooseItemSearchableItem, Never>()

    @Published var sections: [ChooseItemListSection] = []
    @Published var searchText: String = ""
    @Published var isSearchFieldFocused: Bool = false
    @Published var isSearchGoing: Bool = false
    @Published var isLoading: Bool = true

    var otherTokensTitle: String { service.otherTokensTitle }

    let chosenToken: any ChooseItemSearchableItem

    private let service: ChooseItemService
    private var allItems: [ChooseItemListSection] = [] // All available items

    @Injected private var notifications: NotificationService

    var searchingTask: Task<Void, Error>?

    init(service: ChooseItemService, chosenToken: any ChooseItemSearchableItem) {
        self.chosenToken = chosenToken
        self.service = service
        super.init()
        bind()
    }
}

private extension ChooseItemViewModel {
    func bind() {
        service.state
            .receive(on: DispatchQueue.main)
            .removeDuplicates { lhs, rhs in
                lhs.status == rhs.status && lhs.value.count == rhs.value.count
            }
            .sink { [weak self] state in
                guard let self else { return }
                switch state.status {
                case .ready:
                    _ = state.apply { data in
                        let dataWithoutChosen = data.map { section in
                            ChooseItemListSection(
                                items: section.items.filter { $0.id != self.chosenToken.id }
                            )
                        }
                        self.allItems = self.service.sort(items: dataWithoutChosen)

                        if !self.isSearchGoing {
                            self.sections = self.allItems
                        }
                    }

                    if self.isLoading {
                        // Show skeleton only once, after that only seamless updates
                        self.isLoading = false
                    }

                default:
                    break
                }

                if state.hasError {
                    self.notifications.showDefaultErrorNotification()
                }
            }
            .store(in: &subscriptions)

        $searchText
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.searchingTask(keyword: value)
            }
            .store(in: &subscriptions)
    }

    func searchingTask(keyword value: String) {
        if searchingTask != nil {
            searchingTask?.cancel()
        }

        searchingTask = Task {
            try Task.checkCancellation()
            self.isSearchGoing = !value.isEmpty

            if value.isEmpty {
                try Task.checkCancellation()

                await MainActor.run {
                    self.sections = self.allItems
                }
            } else {
                // Do not split up sections if there is a keyword
                var searchedItems: [any ChooseItemSearchableItem] = []
                
                for section in self.allItems {
                    for item in section.items {
                        if item.matches(keyword: value.lowercased()) {
                            try Task.checkCancellation()
                            searchedItems.append(item)
                        }
                    }
                }
                
                try Task.checkCancellation()
                let result = self.service.sortFiltered(
                    by: value.lowercased(),
                    items: [ChooseItemListSection(items: searchedItems)]
                )
                
                try Task.checkCancellation()
                await MainActor.run {
                    self.sections = result
                }
            }
        }
    }
}
