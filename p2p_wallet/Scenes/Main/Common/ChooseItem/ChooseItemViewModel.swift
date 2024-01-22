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
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            .map { [weak self] (input: String) -> (String, [ChooseItemListSection]) in
                if input.isEmpty {
                    return (input, [])
                } else {
                    guard let self else { return (input, []) }
                    // Do not split up sections if there is a keyword
                    let searchedItems = self.allItems
                        .flatMap(\.items)
                        .filter { $0.matches(keyword: input.lowercased()) }
                    let result = self.service.sortFiltered(
                        by: input.lowercased(),
                        items: [ChooseItemListSection(items: searchedItems)]
                    )

                    return (input, result)
                }
            }
            .receive(on: RunLoop.main)
            .sinkAsync(receiveValue: { [weak self] value, result in
                guard let self else { return }
                self.isSearchGoing = !value.isEmpty
                if value.isEmpty {
                    self.sections = self.allItems
                } else {
                    self.sections = result
                }
            })
            .store(in: &subscriptions)
    }
}
