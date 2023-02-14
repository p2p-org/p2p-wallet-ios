import Combine
import Resolver
import SolanaSwift

final class ChooseItemViewModel: BaseViewModel, ObservableObject {

    @Injected private var walletsRepository: WalletsRepository
    @Injected private var notifications: NotificationService

    let chooseTokenSubject = PassthroughSubject<any ChooseItemSearchableItem, Never>()

    @Published var sections: [ChooseItemListSection] = []
    @Published var searchText: String = ""
    @Published var isSearchFieldFocused: Bool = false
    @Published var isSearchGoing: Bool = false
    @Published var isLoading: Bool = true

    var chosenTokenTitle: String { service.chosenTokenTitle }
    var otherTokensTitle: String { service.otherTokensTitle }

    let chosenToken: any ChooseItemSearchableItem

    private let service: ChooseItemService
    private var allItems: [ChooseItemListSection] = [] // All avaialble items

    init(service: ChooseItemService, chosenToken: any ChooseItemSearchableItem) {
        self.chosenToken = chosenToken
        self.service = service
        super.init()

        Task {
            self.isLoading = true
            do {
                self.allItems = try await service.fetchItems()
                self.allItems = allItems.map { section in
                    ChooseItemListSection(items: section.items.filter({ $0.id != chosenToken.id }))
                }
                self.sections = self.service.filterAndSort(items: allItems, by: "")
                self.isLoading = false
            }
            catch {
                self.isLoading = false
                self.notifications.showDefaultErrorNotification()
            }
        }

        $searchText
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sinkAsync(receiveValue: { [weak self] value in
                guard let self else { return }
                self.isSearchGoing = !value.isEmpty
                if value.isEmpty {
                    self.allItems = self.allItems.map { section in
                        ChooseItemListSection(items: section.items.filter({ $0.id != chosenToken.id }))
                    }
                    self.sections = self.service.filterAndSort(items: self.allItems, by: "")
                } else {
                    self.sections = self.service.filterAndSort(items: self.allItems, by: value)
                }
            })
            .store(in: &subscriptions)
    }
}
