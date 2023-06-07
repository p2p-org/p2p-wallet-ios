import BankTransfer
import Combine
import Foundation
import Resolver

final class TopupActionsViewModel: BaseViewModel, ObservableObject {

    @Injected private var bankTransferService: any BankTransferService
    @Injected private var notificationService: NotificationService
    @Injected private var metadataService: WalletMetadataService

    // MARK: -

    @Published var actions: [ActionItem] = [
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
        if !shouldShowBankTransfer {
            return tappedItemSubject.eraseToAnyPublisher()
        }
        return tappedItemSubject.flatMap { [unowned self] action in
            switch action {
            // If it's transfer we need to check if the service is ready
            case .transfer:
                return self.bankTransferService.state.filter { state in
                    return !state.hasError && !state.isFetching
                }.map { _ in Action.transfer }.eraseToAnyPublisher()
            default:
                // Otherwise just pass action
                return Just(action).eraseToAnyPublisher()
            }
        }.eraseToAnyPublisher()
    }

    private let tappedItemSubject = PassthroughSubject<Action, Never>()
    private let shouldShowErrorSubject = CurrentValueSubject<Bool, Never>(false)
    private var shouldShowBankTransfer: Bool {
        available(.bankTransfer) && metadataService.metadata.value != nil
    }

    func didTapItem(item: ActionItem) {
        tappedItemSubject.send(item.id)
    }

    override init() {
        super.init()

        if shouldShowBankTransfer {
            actions.insert(
                ActionItem(
                    id: .transfer,
                    icon: .bankTransferBankIcon,
                    title: L10n.bankTransfer,
                    subtitle: L10n.upTo3Days·Fees("0%"),
                    isLoading: false
                ),
                at: 0
            )
            bindBankTransfer()
        }
    }

    private func bindBankTransfer() {
        // Sending tapped event only after BTS is in ready state
        Publishers.CombineLatest(
            bankTransferService.state,
            tappedItemSubject.eraseToAnyPublisher()
        ).filter { _, action in
            action == .transfer
        }.sinkAsync { [weak self] state, action in
            await MainActor.run {
                self?.setTransferLoadingState(isLoading: state.status != .ready && !state.hasError)
                // Toggling error
                if self?.shouldShowErrorSubject.value == false {
                    self?.shouldShowErrorSubject.send(state.hasError)
                }
            }
        }.store(in: &subscriptions)

        tappedItemSubject.withLatestFrom(bankTransferService.state).filter({ state in
            state.hasError
        }).sinkAsync { [weak self] state in
            await MainActor.run {
                self?.setTransferLoadingState(isLoading: true)
                self?.shouldShowErrorSubject.send(false)
            }
            await self?.bankTransferService.reload()
        }.store(in: &subscriptions)

        shouldShowErrorSubject.filter { $0 }.sinkAsync { [weak self] value in
            await MainActor.run {
                self?.notificationService.showToast(title: "❌", text: L10n.somethingWentWrong)
            }
        }.store(in: &subscriptions)

        bankTransferService.state.filter({ state in
            state.status == .initializing
        }).sinkAsync { [weak self] state in
            await self?.bankTransferService.reload()
        }.store(in: &subscriptions)
    }

    private func setTransferLoadingState(isLoading: Bool) {
        guard let idx = self.actions.firstIndex(where: { act in
            act.id == .transfer
        }) else { return }
        self.actions[idx].isLoading = isLoading
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
