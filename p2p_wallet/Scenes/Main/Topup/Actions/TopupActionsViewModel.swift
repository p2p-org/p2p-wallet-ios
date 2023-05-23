import Foundation
import Combine

final class TopupActionsViewModel: ObservableObject {

    // MARK: -

    @Published var actions: [ActionItem] = [
        ActionItem(
            id: .transfer,
            icon: .bankTransferBankIcon,
            title: L10n.bankTransfer,
            subtitle: L10n.upTo3Days·Fees("0%")
        ),
        ActionItem(
            id: .card,
            icon: .bankTransferCardIcon,
            title: L10n.bankCard,
            subtitle: L10n.instant·Fees("4.5%")
        ),
        ActionItem(
            id: .crypto,
            icon: .bankTransferCryptoIcon,
            title: L10n.crypto,
            subtitle: L10n.upTo1Hour·Fees("%0")
        )
    ]

    var tappedItem: AnyPublisher<Action, Never> {
        tappedItemSubject.eraseToAnyPublisher()
    }

    private let tappedItemSubject = PassthroughSubject<Action, Never>()

    func didTapItem(item: ActionItem) {
        tappedItemSubject.send(item.id)
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
    }
}
