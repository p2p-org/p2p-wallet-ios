import Combine
import AnalyticsManager
import Foundation
import SwiftUI
import SwiftyUserDefaults
import Sell
import Resolver

final class ActionsViewModel: BaseViewModel, ObservableObject {
    @Injected private var sellDataService: any SellDataService
    @Injected private var walletsRepository: WalletsRepository
    @Injected private var analyticsManager: AnalyticsManager

    @Published var horizontal: [ActionCellItem] = []
    @Published var vertical: [ActionCellItem] = []

    var action: AnyPublisher<ActionsView.Action, Never> {
        actionSubject.eraseToAnyPublisher()
    }
    private var actionSubject = PassthroughSubject<ActionsView.Action, Never>()

    var isSellAvailable: Bool {
        available(.sellScenarioEnabled) &&
        sellDataService.isAvailable &&
        !walletsRepository.getWallets().isTotalAmountEmpty
    }
    var isBankTransferAvailable: Bool {
        available(.bankTransfer)
    }

    override init() {
        super.init()

        let cashOut = ActionCellItem(
            id: L10n.cashOut,
            image: .actionsCashOut,
            title: L10n.cashOut,
            subtitle: L10n.cashOutCryptoToFiat) { [weak self] in
                self?.actionSubject.send(.cashOut)
            }
        let topUp = ActionCellItem(
            id: L10n.topUp,
            image: .actionsTopupIcon,
            title: L10n.topUp,
            subtitle: L10n.bankCardBankTransferOrCrypto) { [weak self] in
                self?.actionSubject.send(.topUp)
            }

        if isSellAvailable {
            vertical.append(cashOut)
        }

        if !isSellAvailable {
            horizontal.append(topUp)
        } else {
            vertical.append(topUp)
        }

        let swap = ActionCellItem(
            id: L10n.swap,
            image: .homeSwapAction,
            title: L10n.swap,
            subtitle: L10n.oneCryptoForAnother) { [weak self] in
                self?.actionSubject.send(.swap)
            }
        vertical.append(swap)
        let send = ActionCellItem(
            id: L10n.send,
            image: .homeSendAction,
            title: L10n.send,
            subtitle: L10n.toUsernameOrAddress) { [weak self] in
                self?.actionSubject.send(.send)
            }
        vertical.append(send)

        action.sink(receiveValue: { [unowned self] actionType in
            switch actionType {
            case .buy, .topUp:
                break
            case .receive:
                analyticsManager.log(event: .actionButtonReceive)
                analyticsManager.log(event: .mainScreenReceiveOpen)
                analyticsManager.log(event: .receiveViewed(fromPage: "Main_Screen"))
            case .swap:
                analyticsManager.log(event: .actionButtonSwap)
                analyticsManager.log(event: .mainScreenSwapOpen)
                analyticsManager.log(event: .swapViewed(lastScreen: "Main_Screen"))
            case .send:
                analyticsManager.log(event: .actionButtonSend)
                analyticsManager.log(event: .mainScreenSendOpen)
                analyticsManager.log(event: .sendViewed(lastScreen: "Main_Screen"))
            case .cashOut:
                analyticsManager.log(event: .sellClicked(source: "Action_Panel"))
            }
        })
        .store(in: &subscriptions)
    }
}

extension ActionsViewModel {
    struct ActionCellItem: Identifiable {
        var id: String
        var image: UIImage
        var title: String
        var subtitle: String
        var action: () -> Void
    }
}
