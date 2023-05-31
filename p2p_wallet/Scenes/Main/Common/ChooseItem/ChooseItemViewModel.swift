import Combine
import Resolver
import SolanaSwift

final class ChooseItemViewModel: BaseViewModel, ObservableObject {

    let chooseTokenSubject = PassthroughSubject<any ChooseItemSearchableItem, Never>()

    @Published var sections: [ChooseItemListSection] = []
    @Published var searchText: String = ""
    @Published var isSearchFieldFocused: Bool = false
    @Published var isSearchGoing: Bool = false
    @Published var isLoading: Bool = true

    var otherTitle: String { service.otherTitle }
    var chosenTitle: String { service.chosenTitle }
    var emptyTitle: String { service.emptyTitle }

    let chosenItem: (any ChooseItemSearchableItem)?

    private let service: ChooseItemService
    private var allItems: [ChooseItemListSection] = [] // All available items

    @Injected private var notifications: NotificationService

    init(service: ChooseItemService, chosenToken: (any ChooseItemSearchableItem)?) {
        self.chosenItem = chosenToken
        self.service = service
        super.init()
        bind()
    }
}

private extension ChooseItemViewModel {
    func bind() {
        service.state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                switch state.status {
                case .ready:
                    _ = state.apply { data in
                        let dataWithoutChosen = data.map { section in
                            ChooseItemListSection(
                                items: section.items.filter { $0.id != self.chosenItem?.id }
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
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sinkAsync(receiveValue: { [weak self] value in
                guard let self else { return }
                self.isSearchGoing = !value.isEmpty
                if value.isEmpty {
                    self.sections = self.allItems
                } else {
                    // Do not split up sections if there is a keyword
                    let searchedItems = self.allItems
                        .flatMap { $0.items }
                        .filter { $0.matches(keyword: value.lowercased()) }
                    self.sections = self.service.sortFiltered(
                        by: value.lowercased(),
                        items: [ChooseItemListSection(items: searchedItems)]
                    )
                }
            })
            .store(in: &subscriptions)
    }
}
