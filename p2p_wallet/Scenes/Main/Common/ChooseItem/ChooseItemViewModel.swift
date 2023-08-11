import Combine
import Resolver
import SolanaSwift
import UIKit

final class ChooseItemViewModel: BaseViewModel, ObservableObject {
    let chooseTokenSubject = PassthroughSubject<any ChooseItemSearchableItem, Never>()

    @Published var sections: [ChooseItemListSection] = []
    @Published var searchText: String = ""
    @Published var isSearchGoing: Bool = false
    @Published var isLoading: Bool = true
    let isSearchEnabled: Bool

    var otherTitle: String { service.otherTitle }
    var chosenTitle: String { service.chosenTitle }
    var emptyTitle: String { service.emptyTitle }

    let chosenItem: (any ChooseItemSearchableItem)?

    private let service: ChooseItemService
    private var allItems: [ChooseItemListSection] = [] // All available items

    @Injected private var notifications: NotificationService

    init(service: ChooseItemService, chosenItem: (any ChooseItemSearchableItem)?, isSearchEnabled: Bool) {
        self.chosenItem = chosenItem
        self.service = service
        self.isSearchEnabled = isSearchEnabled
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
            .receive(on: RunLoop.main)
            .handleEvents(receiveOutput: { [unowned self] value in
                isSearchGoing = !value.isEmpty
            })
            .map { [unowned self] value in
                guard !value.isEmpty else {
                    return allItems
                }
                let searchedItems = allItems
                    .flatMap(\.items)
                    .filter { $0.matches(keyword: value.lowercased()) }
                return service.sortFiltered(
                    by: value.lowercased(),
                    items: [ChooseItemListSection(items: searchedItems)]
                )
            }
            .receive(on: RunLoop.main)
            .assignWeak(to: \.sections, on: self)
            .store(in: &subscriptions)
    }
}
