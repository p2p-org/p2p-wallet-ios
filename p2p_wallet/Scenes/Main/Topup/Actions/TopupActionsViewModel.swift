import BankTransfer
import Combine
import Foundation
import Resolver

final class TopupActionsViewModel: BaseViewModel, ObservableObject {

    @Injected private var bankTransferService: any BankTransferService

    // MARK: -

    @Published var actions: [ActionItem] = [
        ActionItem(
            id: .transfer,
            icon: .bankTransferBankIcon,
            title: L10n.bankTransfer,
            subtitle: L10n.upTo3Days·Fees("0%"),
            isLoading: true
        ),
        ActionItem(
            id: .card,
            icon: .bankTransferCardIcon,
            title: L10n.bankCard,
            subtitle: L10n.instant·Fees("4.5%"),
            isLoading: false
        ),
        ActionItem(
            id: .crypto,
            icon: .bankTransferCryptoIcon,
            title: L10n.crypto,
            subtitle: L10n.upTo1Hour·Fees("%0"),
            isLoading: false
        )
    ]

    var tappedItem: AnyPublisher<Action, Never> {
        tappedItemSubject.eraseToAnyPublisher()
    }

    private let tappedItemSubject = PassthroughSubject<Action, Never>()

    func didTapItem(item: ActionItem) {
        guard !item.isLoading else { return }
        tappedItemSubject.send(item.id)
    }

    override init() {
        super.init()

        bankTransferService.userData.sink { _ in
            guard let index = self.actions.firstIndex(where: { item in
                item.id == .transfer
            }) else { return }
            self.actions[index].isLoading = false
        }.store(in: &subscriptions)
    }

}

extension TopupActionsViewModel {
    enum Action: String {
        case transfer
        case card
        case crypto
    }

    struct ActionItem: Identifiable {
        var id: TopupActionsViewModel.Action
        var icon: UIImage
        var title: String
        var subtitle: String
        var isLoading: Bool
    }
}
