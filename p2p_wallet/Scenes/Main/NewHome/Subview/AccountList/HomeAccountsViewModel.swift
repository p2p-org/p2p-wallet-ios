import AnalyticsManager
import BankTransfer
import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Onboarding
import Resolver
import Sell
import SolanaSwift
import SwiftyUserDefaults
import Web3
import Wormhole

final class HomeAccountsViewModel: BaseViewModel, ObservableObject {
    private var defaultsDisposables: [DefaultsDisposable] = []

    // MARK: - Dependencies

    private let solanaAccountsService: SolanaAccountsService

    private let favouriteAccountsStore: FavouriteAccountsDataSource

    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var notificationService: NotificationService
    @Injected private var bankTransferService: AnyBankTransferService<StrigaBankTransferUserDataRepository>
    @Injected private var metadataService: WalletMetadataService

    // MARK: - Properties

    let navigation: PassthroughSubject<HomeNavigation, Never>
    let bannerTapped = PassthroughSubject<Void, Never>()
    private let shouldOpenBankTransfer = PassthroughSubject<Void, Never>()
    private let shouldShowErrorSubject = CurrentValueSubject<Bool, Never>(false)

    @Published private(set) var balance: String = ""
    @Published private(set) var usdcAmount: String = ""
    @Published private(set) var actions: [HomeAction] = []
    @Published private(set) var scrollOnTheTop = true
    @Published private(set) var hideZeroBalance: Bool = Defaults.hideZeroBalances
    @Published private(set) var smallBanner: HomeBannerParameters?
    @Published private(set) var shouldCloseBanner = false

    @SwiftyUserDefault(keyPath: \.homeBannerVisibility, options: .cached)
    private var smallBannerVisibility: HomeBannerVisibility?

    /// Primary list accounts.
    @Published var accounts: [any RenderableAccount] = []

    /// Secondary list accounts. Will be normally hidded and need to be manually action from user to show in view.
    var hiddenAccounts: [any RenderableAccount] = []

    // MARK: - Initializer

    init(
        solanaAccountsService: SolanaAccountsService = Resolver.resolve(),
        ethereumAccountsService: EthereumAccountsService = Resolver.resolve(),
        userActionService: UserActionService = Resolver.resolve(),
        favouriteAccountsStore: FavouriteAccountsDataSource = Resolver.resolve(),
        sellDataService _: any SellDataService = Resolver.resolve(),
        navigation: PassthroughSubject<HomeNavigation, Never>
    ) {
        self.navigation = navigation
        self.solanaAccountsService = solanaAccountsService
        self.favouriteAccountsStore = favouriteAccountsStore

        actions = [.addMoney]

        super.init()
        bindTransferData()
        addWithdrawIfNeeded()

        // TODO: Replace with combine
        defaultsDisposables.append(Defaults.observe(\.hideZeroBalances) { [weak self] change in
            self?.hideZeroBalance = change.newValue ?? false
        })

        // Ethereum accounts
        let ethereumAggregator = HomeEthereumAccountsAggregator()
        let ethereumAccountsPublisher = Publishers
            .CombineLatest(
                ethereumAccountsService.statePublisher,
                userActionService.$actions.map { userActions in
                    userActions.compactMap { $0 as? WormholeClaimUserAction }
                }
            )
            .map { state, actions in
                ethereumAggregator.transform(input: (state.value, actions))
            }

        // Solana accounts
        let solanaAggregator = HomeSolanaAccountsAggregator()
        let solanaAccountsPublisher = Publishers
            .CombineLatest4(
                solanaAccountsService.statePublisher,
                favouriteAccountsStore.$favourites,
                favouriteAccountsStore.$ignores,
                $hideZeroBalance
            )
            .map { state, favourites, ignores, hideZeroBalance in
                solanaAggregator.transform(input: (state.value, favourites, ignores, hideZeroBalance))
            }

        // bankTransferPublisher
        let bankTransferServicePublisher = Publishers.CombineLatest(
            bankTransferService.value.state
                .compactMap { $0.value.wallet?.accounts },
            userActionService.$actions

        )
            .compactMap { (account, actions) -> [any RenderableAccount] in
                BankTransferRenderableAccountFactory.renderableAccount(
                    accounts: account,
                    actions: actions
                )
            }

        let homeAccountsAggregator = HomeAccountsAggregator()
        Publishers
            .CombineLatest3(
                solanaAccountsPublisher,
                ethereumAccountsPublisher,
                bankTransferServicePublisher.prepend([])
            )
            .map { solanaAccounts, ethereumAccounts, bankTransferAccounts in
                homeAccountsAggregator
                    .transform(input: (solanaAccounts, ethereumAccounts, bankTransferAccounts))
            }
            .receive(on: RunLoop.main)
            .sink { primary, secondary in
                self.accounts = primary
                self.hiddenAccounts = secondary
            }
            .store(in: &subscriptions)

        // Balance
        solanaAccountsService.statePublisher
            .map { (state: AsyncValueState<[SolanaAccountsService.Account]>) -> String in
                let equityValue: CurrencyAmount = state.value
                    .filter(\.isUSDC)
                    .filter { $0.token.keyAppExtensions.calculationOfFinalBalanceOnWS ?? true }
                    .reduce(CurrencyAmount(usd: 0)) {
                        if $1.token.keyAppExtensions.ruleOfProcessingTokenPriceWS == .byCountOfTokensValue {
                            return $0 + CurrencyAmount(usd: $1.cryptoAmount.amount)
                        } else {
                            return $0 + $1.amountInFiat
                        }
                    }

                let formatter = CurrencyFormatter(
                    showSpacingAfterCurrencySymbol: false,
                    showSpacingAfterCurrencyGroup: false,
                    showSpacingAfterLessThanOperator: false
                )
                return formatter.string(amount: equityValue)
            }
            .receive(on: RunLoop.main)
            .assignWeak(to: \.balance, on: self)
            .store(in: &subscriptions)

        userActionService.$actions
            .compactMap { $0.compactMap { $0 as? BankTransferClaimUserAction }.first }
            .flatMap(\.publisher)
            .filter { $0.status == .ready }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .handleEvents(receiveOutput: { [weak self] val in
                switch val.status {
                case .error(let concreteType):
                    self?.handle(error: concreteType)
                default:
                    break
                }
            })
            .sink { [weak self] action in
                guard let result = action.result else { return }
                self?.handleClaim(result: result, in: action)
            }.store(in: &subscriptions)

            userActionService.$actions
            .compactMap { $0.compactMap { $0 as? OutgoingBankTransferUserAction } }
            .flatMap(\.publisher)
            .filter { $0.status != .pending && $0.status != .processing }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] action in
                switch action.status {
                case .ready:
                    guard let result = action.result else { return }
                    self?.handleOutgoingConfirm(result: result, in: action)
                case let .error(concreteType):
                    self?.handle(error: concreteType)
                default:
                    break
                }
            }
            .store(in: &subscriptions)

        analyticsManager.log(event: .claimAvailable(claim: available(.ethAddressEnabled)))

        // USDC amount
        solanaAccountsService.statePublisher
            .map { (state: AsyncValueState<[SolanaAccountsService.Account]>) -> String in
                guard let usdcAccount = state.value.first(where: { $0.isUSDC }) else {
                    return ""
                }

                let cryptoFormatter = CryptoFormatter()
                return cryptoFormatter.string(amount: usdcAccount.cryptoAmount)
            }
            .receive(on: RunLoop.main)
            .assignWeak(to: \.usdcAmount, on: self)
            .store(in: &subscriptions)
    }

    func refresh() async {
        await HomeAccountsSynchronisationService().refresh()
    }

    func invoke(for account: any RenderableAccount, event: Event) {
        switch account {
        case let renderableAccount as RenderableSolanaAccount:
            switch event {
            case .tap:
                navigation.send(.solanaAccount(renderableAccount.account))
            case .visibleToggle:
                let pubkey = renderableAccount.account.address
                let tags = renderableAccount.tags

                if tags.contains(.ignore) {
                    favouriteAccountsStore.markAsFavourite(key: pubkey)
                } else if tags.contains(.favourite) {
                    favouriteAccountsStore.markAsIgnore(key: pubkey)
                } else {
                    favouriteAccountsStore.markAsIgnore(key: pubkey)
                }
            default:
                break
            }

        case let renderableAccount as RenderableEthereumAccount:
            switch event {
            case .extraButtonTap:
                navigation
                    .send(.claim(renderableAccount.account, renderableAccount.userAction as? WormholeClaimUserAction))
            default:
                break
            }

        case let renderableAccount as BankTransferRenderableAccount:
            handleBankTransfer(account: renderableAccount)

        case let renderableAccount as OutgoingBankTransferRenderableAccount:
            handleBankTransfer(account: renderableAccount)

        default:
            break
        }
    }

    func actionClicked(_ action: HomeAction) {
        switch action {
        case .addMoney:
            analyticsManager.log(event: .mainScreenAddMoneyClick)
            navigation.send(.addMoney)
        case .withdraw:
            analyticsManager.log(event: .mainScreenWithdrawClick)
            navigation.send(.withdrawCalculator)
        }
    }

    func scrollToTop() {
        scrollOnTheTop = true
    }
    
    func viewDidAppear() {
        if let balance = Double(balance) {
            analyticsManager.log(event: .userAggregateBalanceBase(amountUsd: balance, currency: Defaults.fiat.code))
            analyticsManager.log(event: .userHasPositiveBalanceBase(state: balance > 0))
        }
    }
    
    func balanceTapped() {
        analyticsManager.log(event: .mainScreenAmountClick)
    }

    func closeBanner(id: String) {
        smallBannerVisibility = HomeBannerVisibility(id: id, closed: true)
        smallBanner = nil
        shouldCloseBanner = false
    }

    func hiddenTokensTapped() {
        analyticsManager.log(event: .mainScreenHiddenTokens)
    }
    
    // Bank transfer
    private func handle(error: UserActionError) {
        switch error {
        case .networkFailure:
            self.notificationService.showConnectionErrorNotification()
        default:
            self.notificationService.showDefaultErrorNotification()
        }
    }

    private func handleBankTransfer(account: OutgoingBankTransferRenderableAccount) {
        let userActionService: UserActionService = Resolver.resolve()
        guard account.status != .isProcessing else { return }
        let userAction = OutgoingBankTransferUserAction(
            id: account.id,
            accountId: account.accountId,
            amount: String(account.rawAmount),
            status: .processing
        )
        // Execute and emit action.
        userActionService.execute(action: userAction)
    }

    private func handleBankTransfer(account: BankTransferRenderableAccount) {
        let userActionService: UserActionService = Resolver.resolve()
        let userWalletManager: UserWalletManager = Resolver.resolve()
        guard
            account.status != .isProcessing,
            let walletPubKey = userWalletManager.wallet?.account.publicKey
        else { return }
        let userAction = BankTransferClaimUserAction(
            id: account.id,
            accountId: account.accountId,
            token: account.token,
            amount: String(account.rawAmount),
            receivingAddress: try! PublicKey.associatedTokenAddress(
                walletAddress: walletPubKey,
                tokenMintAddress: try! PublicKey(string: Token.usdc.address)
            ).base58EncodedString,
            status: .processing
        )

        // Execute and emit action.
        userActionService.execute(action: userAction)
    }

    private func handleOutgoingConfirm(
        result: OutgoingBankTransferUserActionResult,
        in action: OutgoingBankTransferUserAction
    ) {
        switch result {
        case let .initiated(challengeId, IBAN, BIC):
            self.navigation.send(.bankTransferConfirm(
                StrigaWithdrawTransaction(
                    challengeId: challengeId,
                    IBAN: IBAN,
                    BIC: BIC,
                    amount: Double(action.amount) ?? 0 / 100,
                    feeAmount: .zero
                )
            ))
        case let .requestWithdrawInfo(receiver):
            self.navigation.send(.withdrawInfo(
                StrigaWithdrawalInfo(receiver: receiver),
                WithdrawConfirmationParameters(accountId: action.accountId, amount: action.amount)
            ))
        }
    }

    private func handleClaim(result: BankTransferClaimUserActionResult, in action: BankTransferClaimUserAction) {
        self.navigation.send(.bankTransferClaim(StrigaClaimTransaction(
            challengeId: action.result?.challengeId ?? "",
            token: action.result?.token ?? .usdc,
            amount: Double(action.amount ?? "") ?? 0,
            feeAmount: .zero,
            fromAddress: action.result?.fromAddress ?? "",
            receivingAddress: action.receivingAddress
        )))
    }

}

extension HomeAccountsViewModel {
    enum Event {
        case tap
        case visibleToggle
        case extraButtonTap
    }
}

// MARK: - Private
private extension HomeAccountsViewModel {
    func addWithdrawIfNeeded() {
        guard available(.bankTransfer) && metadataService.metadata.value != nil else { return }
        // If striga is enabled and user is web3 authed
        actions.append(.withdraw)
    }

    func bindTransferData() {
        bankTransferService.value.state
            .filter { !$0.isFetching }
            .filter { $0.value.userId != nil && $0.value.mobileVerified }
            .filter { [weak self] in
                // If banner with the same KYC status was already tapped, then we do not show it again
                guard let bannerVisibility = self?.smallBannerVisibility else { return true }
                return bannerVisibility.id != $0.value.kycStatus.rawValue || !bannerVisibility.closed
            }
            .map { value in
                HomeBannerParameters(
                    status: value.value.kycStatus,
                    action: { [weak self] in self?.bannerTapped.send() },
                    isLoading: false,
                    isSmallBanner: true
                )
            }
            .assignWeak(to: \.smallBanner, on: self)
            .store(in: &subscriptions)

        shouldOpenBankTransfer
            .withLatestFrom(bankTransferService.value.state)
            .receive(on: RunLoop.main)
            .sink{ [weak self] state in
                if state.value.isIBANNotReady {
                    self?.shouldShowErrorSubject.send(true)
                } else {
                    self?.navigation.send(.bankTransfer)
                }
            }
            .store(in: &subscriptions)

        shouldShowErrorSubject
            .filter { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.notificationService.showToast(title: "❌", text: L10n.somethingWentWrong)
                self?.shouldShowErrorSubject.send(false)
            }
            .store(in: &subscriptions)

        bannerTapped
            .withLatestFrom(bankTransferService.value.state)
            .filter { !$0.isFetching }
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                guard let self else { return }
                self.requestCloseBanner(for: state.value)

                if state.value.isIBANNotReady {
                    self.smallBanner?.button?.isLoading = true
                    Task {
                        await self.bankTransferService.value.reload()
                        self.shouldOpenBankTransfer.send()
                    }
                } else {
                    self.shouldOpenBankTransfer.send()
                }
            }
            .store(in: &subscriptions)
    }

    func requestCloseBanner(for data: UserData) {
        switch data.kycStatus {
        case .onHold, .pendingReview:
            shouldCloseBanner = false
        case .approved:
            shouldCloseBanner = data.isIBANNotReady == false
        default:
             shouldCloseBanner = true
        }
    }
}
