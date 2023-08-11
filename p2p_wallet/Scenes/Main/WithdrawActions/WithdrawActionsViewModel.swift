import Combine
import CountriesAPI
import Foundation
import Onboarding
import Resolver
import UIKit

final class WithdrawActionsViewModel: BaseViewModel, ObservableObject {
    @Injected private var metadataService: WalletMetadataService

    // MARK: -

    @Published var actions: [ActionItem] = []

    var tappedItem: AnyPublisher<Action, Never> {
        tappedItemSubject.eraseToAnyPublisher()
    }

    private let tappedItemSubject = PassthroughSubject<Action, Never>()
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

        if let region = Defaults.region, region.isStrigaAllowed {
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
