import AnalyticsManager
import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Reachability
import Resolver
import Wormhole

class WormholeClaimViewModel: BaseViewModel, ObservableObject {
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var reachability: Reachability
    @Injected private var notificationService: NotificationService
    @Injected private var accountStorage: AccountStorageType

    let action: PassthroughSubject<Action, Never> = .init()

    private let bundle: AsyncValue<WormholeBundle?>

    @Published var model: any WormholeClaimModel

    init(model: WormholeClaimMockModel) {
        self.model = model
        bundle = .init(just: nil)

        super.init()
    }

    init(
        account: EthereumAccount,
        ethereumAccountsService _: EthereumAccountsService = Resolver.resolve(),
        wormholeAPI: WormholeService = Resolver.resolve()
    ) {
        model = WormholeClaimEthereumModel(account: account, bundle: .init(value: nil))
        bundle = .init(initialItem: nil) {
            // Request to get bundle
            do {
                return try await(wormholeAPI.getBundle(account: account), nil)
            } catch {
                return (nil, error)
            }
        }

        super.init()

        bundle
            .statePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.model = WormholeClaimEthereumModel(account: account, bundle: state)
            }
            .store(in: &subscriptions)

        // Update timer
        bundle
            .statePublisher
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
        bundle
            .statePublisher
            .debounce(for: 0.01, scheduler: DispatchQueue.main)
            .map(\.error)
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.logAlert(for: account, error: error)
                if let error = error as? JSONRPCError<String>, error.code == -32007 {
                    self?.notificationService
                        .showInAppNotification(.error(L10n.theFeesAreBiggerThanTheTransactionAmount))
                } else {
                    self?.notificationService.showToast(title: nil, text: L10n.WormholeBridgeIsCurrentlyUnable.pleaseTryAgainLater, haptic: false)
                }
            }
            .store(in: &subscriptions)

        // Network setup
        try? reachability.startNotifier()
        reachability.status.sink { [weak self] _ in
            _ = self?.reachability.check()
        }.store(in: &subscriptions)

        // Start fetch bundle
        bundle.fetch()
    }

    /// Open fee view.
    func openFees() {
        action.send(.openFee(bundle))
    }

    /// Start claiming.
    func claim() {
        if let model = model as? WormholeClaimEthereumModel {
            if bundle.state.hasError {
                if let error = bundle.state.error as? JSONRPCError<String>, error.code == -32007 {
                    action.send(.openReceive)
                    return
                }
                bundle.fetch()
            } else {
                guard let bundle = bundle.state.value else {
                    DefaultLogManager.shared.log(error: Error.missingBundle)
                    return
                }

                // Setup
                let userActionService: UserActionService = Resolver.resolve()

                let userAction = WormholeClaimUserAction(
                    token: model.account.token,
                    bundle: bundle
                )

                // Execute and emit action.
                userActionService.execute(action: userAction)
                action.send(.claiming(userAction))

                // Log
                analyticsManager.log(event: .claimBridgesClickConfirmed(
                    tokenName: model.account.token.symbol,
                    tokenValue: bundle.resultAmount.asCryptoAmount.amount.description.double ?? 0,
                    valueFiat: bundle.resultAmount.asCurrencyAmount.value.description.double ?? 0,
                    free: bundle.resultAmount.asCurrencyAmount.value.description.double ?? 0 >= 50
                ))
            }
        }
    }

    private func logAlert(for account: EthereumAccount, error: Swift.Error) {
        let token: ClaimAlertLoggerErrorMessage.Token = .init(
            name: account.token.name,
            solanaMint: SupportedToken.ERC20(rawValue: account.token.erc20Address ?? "")?.solanaMintAddress ?? "",
            ethMint: account.token.tokenPrimaryKey,
            claimAmount: ethModel == nil ? "0" : CryptoAmount(amount: ethModel!.account.balance, token: account.token).amount.description
        )

        DefaultLogManager.shared.log(
            event: "Wormhole Claim iOS Alarm",
            logLevel: .alert,
            data:
                ClaimAlertLoggerErrorMessage(
                    tokenToClaim: token,
                    userPubkey: accountStorage.account?.publicKey.base58EncodedString ?? "",
                    userEthPubkey: ethModel?.account.address ?? "",
                    simulationError: nil,
                    bridgeSeviceError: error.readableDescription,
                    feeRelayerError: nil,
                    blockchainError: nil
                )
        )
    }

    var ethModel: WormholeClaimEthereumModel? { model as? WormholeClaimEthereumModel }
}

extension WormholeClaimViewModel {
    enum Action {
        case openFee(AsyncValue<WormholeBundle?>)
        case claiming(WormholeClaimUserAction)
        case openReceive
    }

    enum Error: Swift.Error {
        case missingBundle
    }
}
