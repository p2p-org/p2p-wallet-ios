import Combine
import SwiftUI
import Foundation
import KeyAppUI
import Sell
import Resolver

@MainActor class ActionsViewModel: BaseViewModel, ObservableObject {

    // MARK: -

    @Injected private var sellDataService: any SellDataService
    @Injected private var walletsRepository: WalletsRepository

    @Published var actions = [ActionViewItem]()

    let coordinatorIO = CoordinatorIO()

    override init() {
        super.init()

        actions = [
            ActionViewItem(
                id: .buy,
                icon: .actionBuy,
                title: L10n.buy,
                subtitle: L10n.usingApplePayOrCreditCard
            ),
            ActionViewItem(
                id: .receive,
                icon: .actionReceive,
                title: L10n.receive,
                subtitle: L10n.fromAnotherWalletOrExchange
            ),
            ActionViewItem(
                id: .send,
                icon: .actionSend,
                title: L10n.send,
                subtitle: L10n.fromAnotherWalletOrExchange
            ),
            ActionViewItem(
                id: .swap,
                icon: .actionSwap,
                title: L10n.swap,
                subtitle: L10n.oneCryptoForAnother
            ),
        ]

        if isSellAvailable {
            actions.insert(
                ActionViewItem(
                    id: .cashOut,
                    icon: .actionCashout,
                    title: L10n.cashOutCryptoToFiat,
                    subtitle: L10n.viaBankTransfer
                ), at: 0
            )
        }
    }

    public func didTapAction(_ action: Action) {
        coordinatorIO.action.send(action)
    }

    public func didTapClose() {
        coordinatorIO.close.send()
    }

    private var isSellAvailable: Bool {
        available(.sellScenarioEnabled) &&
        sellDataService.isAvailable &&
        !walletsRepository.getWallets().isTotalBalanceEmpty
    }
}

extension ActionsViewModel {
    struct CoordinatorIO {
        var close = PassthroughSubject<Void, Never>()
        var action = PassthroughSubject<Action, Never>()
    }

    enum Action: String {
        case buy
        case receive
        case swap
        case send
        case cashOut
    }
}

struct ActionViewItem: Identifiable {
    var id: ActionsViewModel.Action
    var icon: UIImage
    var title: String
    var subtitle: String
}
