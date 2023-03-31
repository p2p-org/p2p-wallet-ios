import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Reachability
import Resolver
import Wormhole

class WormholeClaimViewModel: BaseViewModel, ObservableObject {
    let action: PassthroughSubject<Action, Never> = .init()

    let bundle: AsyncValue<WormholeBundle?>

    @Published var model: any WormholeClaimModel
    @Published var feeAmountInFiat: String = ""

    @Injected private var reachability: Reachability

    init(model: WormholeClaimMockModel) {
        self.model = model
        self.bundle = .init(just: nil)

        super.init()
    }

    init(
        account: EthereumAccount,
        ethereumAccountsService: EthereumAccountsService = Resolver.resolve(),
        wormholeAPI: WormholeService = Resolver.resolve(),
        notificationService: NotificationService = Resolver.resolve()
    ) {
        self.model = WormholeClaimEthereumModel(account: account, bundle: .init(value: nil))
        self.bundle = .init(initialItem: nil) {
            // Request to get bundle
            do {
                return try await (wormholeAPI.getBundle(account: account), nil)
            } catch {
                return (nil, error)
            }
        }

        super.init()

        // Start fetch bundle
        bundle.fetch()

        // Listen changing in bundle value
        bundle.listen(target: self, in: &subscriptions)

        bundle.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.model = WormholeClaimEthereumModel(account: account, bundle: state)
            }
            .store(in: &subscriptions)

        // Update timer
        bundle.$state
            .map(\.value?.expiresAtDate)
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] expiresAtDate in
                guard let self = self else { return }

                let elapsed = expiresAtDate.timeIntervalSince(Date()) - 1

                DispatchQueue.main.asyncAfter(deadline: .now() + elapsed) { [weak self] in
                    self?.bundle.fetch()
                }
            }
            .store(in: &subscriptions)

        // Notify user an error
        bundle.$state
            .map(\.error)
            .compactMap { $0 }
            .sink { error in
                if let error = error as? JSONRPCError<String>, error.code == -32007 {
                    notificationService.showInAppNotification(.error(L10n.theFeesAreBiggerThanTheTransactionAmount))
                }
                DispatchQueue.main.async {
                    self.feeAmountInFiat = L10n.valueIsUnavailable
                }
            }
            .store(in: &subscriptions)

        try? reachability.startNotifier()
        reachability.status.sink { [unowned self] _ in
            _ = self.reachability.check()
        }.store(in: &subscriptions)
    }

    func claim() {
        if let model = model as? WormholeClaimEthereumModel {
            if bundle.state.hasError {
                bundle.fetch()
            } else {
                guard let bundle = bundle.state.value else {
                    Error.missingBundle.capture()
                    return
                }

                let rawTransaction = WormholeClaimTransaction(
                    wormholeService: Resolver.resolve(),
                    token: model.account.token,
                    amountInCrypto: model.account.representedBalance,
                    amountInFiat: model.account.balanceInFiat,
                    bundle: bundle
                )

                let transactionHandler: TransactionHandler = Resolver.resolve()
                let index = transactionHandler.sendTransaction(rawTransaction)
                let pendingTransaction = transactionHandler.getProcessingTransaction(index: index)

                action.send(.claiming(pendingTransaction))
            }
        }
    }
}

extension WormholeClaimViewModel {
    enum Action {
        case openFee(AsyncValue<WormholeBundle?>)
        case claiming(PendingTransaction)
    }

    enum Error: Swift.Error {
        case missingBundle
    }
}
