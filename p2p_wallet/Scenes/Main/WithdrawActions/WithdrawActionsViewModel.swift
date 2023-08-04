import BankTransfer
import CountriesAPI
import Combine
import Foundation
import Resolver
import UIKit
import Onboarding

final class WithdrawActionsViewModel: BaseViewModel, ObservableObject {

    @Injected private var bankTransferService: any BankTransferService
    @Injected private var notificationService: NotificationService
    @Injected private var metadataService: WalletMetadataService

    // MARK: -

    @Published var actions: [ActionItem] = []

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

        actions.insert(
            ActionItem(
                id: .wallet,
                icon: .withdrawActionsCrypto,
                title: L10n.cryptoExchangeOrWallet,
                subtitle: L10n.fee("0%"),
                isLoading: false,
                isDisabled: false
            ),
            at: 0
        )

        actions.insert(
            ActionItem(
                id: .user,
                icon: .withdrawActionsUser,
                title: L10n.keyAppUser,
                subtitle: L10n.fee("0%"),
                isLoading: false,
                isDisabled: false
            ),
            at: 0
        )

        if let region = Defaults.region {
            actions.insert(
                ActionItem(
                    id: .transfer,
                    icon: region.isStrigaAllowed ? .withdrawActionsTransfer : .addMoneyBankTransferDisabled,
                    title: L10n.myBankAccount,
                    subtitle: L10n.fee("1%"),
                    isLoading: false,
                    isDisabled: !region.isStrigaAllowed
                ),
                at: 0
            )
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

extension WithdrawActionsViewModel {
    enum Action: String {
        case transfer
        case user
        case wallet
    }

    struct ActionItem: Identifiable {
        var id: WithdrawActionsViewModel.Action
        var icon: UIImage
        var title: String
        var subtitle: String
        var isLoading: Bool
        var isDisabled: Bool
    }
}
