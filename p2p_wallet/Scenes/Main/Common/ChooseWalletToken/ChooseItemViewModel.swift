import Combine
import Resolver
import SolanaSwift

struct ChooseItemListData: Identifiable {
    let id: UUID
    let items: [any SearchableItem]
}

final class ChooseItemViewModel: BaseViewModel, ObservableObject {

    @Injected private var walletsRepository: WalletsRepository
    @Injected private var notifications: NotificationService

    let chooseTokenSubject = PassthroughSubject<any SearchableItem, Never>()
    let clearSearch = PassthroughSubject<Void, Never>()

    @Published var wallets: [ChooseItemListData] = []
    @Published var searchText: String = ""
    @Published var isSearchFieldFocused: Bool = true
    @Published var isSearchGoing: Bool = false
    @Published var isLoading: Bool = true

    let chosenToken: any SearchableItem

    private let service: ChooseItemService
    private var allWallets: [ChooseItemListData] = []

    init(service: ChooseItemService, chosenToken: any SearchableItem) {
        self.chosenToken = chosenToken
        self.service = service
        super.init()

        Task {
            self.isLoading = true
            do {
                self.allWallets = try await service.fetchItems()
                self.allWallets = allWallets.map { section in
                    ChooseItemListData(id: .init(), items: section.items.filter({ $0.id != chosenToken.id }))
                }
                self.wallets = self.service.filterAndSort(items: allWallets, by: "")
                self.isLoading = false
            }
            catch {
                self.isLoading = false
                self.notifications.showDefaultErrorNotification()
            }
        }

        $searchText
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self = self else { return }
                self.isSearchGoing = !value.isEmpty
                if value.isEmpty {
                    self.allWallets = self.allWallets.map { section in
                        ChooseItemListData(id: .init(), items: section.items.filter({ $0.id != chosenToken.id }))
                    }
                    self.wallets = self.service.filterAndSort(items: self.allWallets, by: "")
                } else {
                    self.wallets = self.service.filterAndSort(items: self.allWallets, by: value)
                }
            }
            .store(in: &subscriptions)

        clearSearch
            .sink { [weak self] in
                self?.searchText = ""
            }
            .store(in: &subscriptions)
    }
}
