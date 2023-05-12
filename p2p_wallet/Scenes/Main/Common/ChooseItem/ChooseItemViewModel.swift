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

    var chosenTokenTitle: String { service.chosenTokenTitle }
    var otherTokensTitle: String { service.otherTokensTitle }

    let chosenToken: any ChooseItemSearchableItem

    private let service: ChooseItemService
    private var allItems: [ChooseItemListSection] = [] // All available items

    @Injected private var walletsRepository: WalletsRepository
    @Injected private var notifications: NotificationService

    init(service: ChooseItemService, chosenToken: any ChooseItemSearchableItem) {
        self.chosenToken = chosenToken
        self.service = service
        super.init()

        self.isLoading = true
        Task {
            do {
                let data = try await service.fetchItems()
                let dataWithoutChosen = data.map { section in
                    ChooseItemListSection(
                        items: section.items.filter { $0.id != chosenToken.id }
                    )
                }
                
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.allItems = self.service.sort(items: dataWithoutChosen)
                    self.sections = self.allItems
                }
                
            }
            catch {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.notifications.showDefaultErrorNotification()
                }
            }
            
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.isLoading = false
            }
        }

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
