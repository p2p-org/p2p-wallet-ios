import BankTransfer
import CountriesAPI
import Combine
import Foundation
import Resolver
import UIKit
import Onboarding

final class TopupActionsViewModel: BaseViewModel, ObservableObject {

    @Injected private var bankTransferService: any BankTransferService
    @Injected private var notificationService: NotificationService
    @Injected private var metadataService: WalletMetadataService

    // MARK: -

    @Published var actions: [ActionItem] = [
        ActionItem(
            id: .crypto,
            icon: .addMoneyCrypto,
            title: L10n.crypto,
            subtitle: L10n.upTo1Hour·Fees("%0"),
            isLoading: false,
            isDisabled: false
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
                    return !state.hasError && !state.isFetching && !state.value.isIBANNotReady
                }.map { _ in Action.transfer }.eraseToAnyPublisher()
            default:
                // Otherwise just pass action
                return Just(action).eraseToAnyPublisher()
            }
        }.eraseToAnyPublisher()
    }

    private let tappedItemSubject = PassthroughSubject<Action, Never>()
    private let shouldCheckBankTransfer = PassthroughSubject<Void, Never>()
    private let shouldShowErrorSubject = CurrentValueSubject<Bool, Never>(false)
    private var shouldShowBankTransfer: Bool {
        // always enabled for mocking
        GlobalAppState.shared.strigaMockingEnabled ? true :
            // for non-mocking need to check
            available(.bankTransfer) && metadataService.metadata.value != nil
    }

    func didTapItem(item: ActionItem) {
        tappedItemSubject.send(item.id)
    }

    override init() {
        super.init()

        if let region = Defaults.region, region.isMoonpayAllowed {
            actions.insert(
                ActionItem(
                    id: .card,
                    icon: region.isMoonpayAllowed ? .addMoneyBankCard : .addMoneyBankCardDisabled,
                    title: L10n.bankCard,
                    subtitle: L10n.instant·Fees("4.5%"),
                    isLoading: false,
                    isDisabled: !region.isMoonpayAllowed
                ),
                at: 0
            )
        }

        let isStrigaAllowed = Defaults.region?.isStrigaAllowed ?? false
        if shouldShowBankTransfer, isStrigaAllowed {
            actions.insert(
                ActionItem(
                    id: .transfer,
                    icon: isStrigaAllowed ? .addMoneyBankTransfer : .addMoneyBankTransferDisabled ,
                    title: L10n.bankTransfer,
                    subtitle: L10n.upTo3Days·Fees("0%"),
                    isLoading: false,
                    isDisabled: !isStrigaAllowed
                ),
                at: 0
            )
            bindBankTransfer()
        }
    }

    private func bindBankTransfer() {
        shouldCheckBankTransfer
            .withLatestFrom(bankTransferService.state)
            .filter({ !$0.isFetching })
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.setTransferLoadingState(isLoading: false)
                // Toggling error
                if self?.shouldShowErrorSubject.value == false {
                    self?.shouldShowErrorSubject.send(state.hasError || state.value.isIBANNotReady)
                }
            }
            .store(in: &subscriptions)

        tappedItemSubject
            .filter({ $0 == .transfer })
            .withLatestFrom(bankTransferService.state).filter({ state in
                state.hasError || state.value.isIBANNotReady
            })
            .sinkAsync { [weak self] state in
                guard let self else { return }
                await MainActor.run {
                    self.setTransferLoadingState(isLoading: true)
                    self.shouldShowErrorSubject.send(false)
                }
                await self.bankTransferService.reload()
                self.shouldCheckBankTransfer.send(())
            }
            .store(in: &subscriptions)

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
        guard let idx = actions.firstIndex(where: { act in
            act.id == .transfer
        }) else { return }
        actions[idx].isLoading = isLoading
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
        var isDisabled: Bool
    }
}
