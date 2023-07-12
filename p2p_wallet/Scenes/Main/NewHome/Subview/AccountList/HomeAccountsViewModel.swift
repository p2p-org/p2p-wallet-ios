import AnalyticsManager
import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import Sell
import SolanaSwift
import SwiftyUserDefaults
import Web3
import Wormhole
import BankTransfer

final class HomeAccountsViewModel: BaseViewModel, ObservableObject {
    private var defaultsDisposables: [DefaultsDisposable] = []

    // MARK: - Dependencies

    private let solanaAccountsService: SolanaAccountsService
    private let ethereumAccountsService: EthereumAccountsService

    private let favouriteAccountsStore: FavouriteAccountsDataSource

    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var notificationService: NotificationService
    @Injected private var bankTransferService: AnyBankTransferService<StrigaBankTransferUserDataRepository>

    // MARK: - Properties

    let navigation: PassthroughSubject<HomeNavigation, Never>
    let bannerTapped = PassthroughSubject<Void, Never>()
    private let tappedBannerSubject = PassthroughSubject<HomeNavigation, Never>()
    private let shouldShowErrorSubject = CurrentValueSubject<Bool, Never>(false)

    @Published private(set) var balance: String = ""
    @Published private(set) var actions: [WalletActionType] = []
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
        sellDataService: any SellDataService = Resolver.resolve(),
        navigation: PassthroughSubject<HomeNavigation, Never>
    ) {
        self.navigation = navigation
        self.solanaAccountsService = solanaAccountsService
        self.ethereumAccountsService = ethereumAccountsService
        self.favouriteAccountsStore = favouriteAccountsStore

        var actions: [WalletActionType] = [.topUp]
        if sellDataService.isAvailable {
            actions.append(.cashOut)
        }
        actions.append(.send)
        self.actions = actions

        super.init()
        bindTransferData()

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
                .compactMap { $0.value.wallet?.accounts.usdc },
            userActionService.$actions.map { userActions in
                userActions.compactMap { $0 as? BankTransferClaimUserAction }
            }
        )
            .compactMap { (account, actions) -> [BankTransferRenderableAccount]? in
                guard
                    account.availableBalance > 0,
                    let address = try? EthereumAddress(
                        hex: EthereumAddresses.ERC20.usdc.rawValue,
                        eip55: false
                    ) else { return nil }

                let token = EthereumToken(
                    name: SolanaToken.usdc.name,
                    symbol: SolanaToken.usdc.symbol,
                    decimals: 6,
                    logo: URL(string: SolanaToken.usdc.logoURI ?? ""),
                    contractType: .erc20(contract: address)
                )

                let action = actions.first(where: { action in
                    action.id == account.accountID
                })
                return [
                    BankTransferRenderableAccount(
                        accountId: account.accountID,
                        token: token,
                        amount: .init(amount: BigUInt(account.availableBalance.toCent()), token: token),
                        status: action?.status == .processing ? .isClaimming : .readyToClaim
                    )
                ]
            }

        let homeAccountsAggregator = HomeAccountsAggregator()
        Publishers
            .CombineLatest3(
                solanaAccountsPublisher,
                ethereumAccountsPublisher,
                bankTransferServicePublisher.prepend([])
            )
            .map { solanaAccounts, ethereumAccounts, bankTransferAccounts in
                homeAccountsAggregator.transform(input: (solanaAccounts, ethereumAccounts, bankTransferAccounts))
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
                let equityValue: Double = state.value.reduce(0) { $0 + $1.amountInFiatDouble }
                return "\(Defaults.fiat.symbol) \(equityValue.toString(maximumFractionDigits: 2))"
            }
            .receive(on: RunLoop.main)
            .assignWeak(to: \.balance, on: self)
            .store(in: &subscriptions)

        userActionService.$actions
            .compactMap {
                $0.compactMap { $0 as? BankTransferClaimUserAction }
            }
            .flatMap { $0.publisher }
            .handleEvents(receiveOutput: { val in
                switch val.status {
                case .error(let error):
                    self.notificationService.showDefaultErrorNotification()
                default:
                    break
                }
            })
            .filter { $0.status == .ready }
            .receive(on: RunLoop.main)
            .sink { [weak self] action in
                self?.navigation.send(.bankTransferClaim(action))
            }.store(in: &subscriptions)

        analyticsManager.log(event: .claimAvailable(claim: available(.ethAddressEnabled)))
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
                guard let pubkey = renderableAccount.account.data.pubkey else { return }
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
                navigation.send(.claim(renderableAccount.account, renderableAccount.userAction))
            default:
                break
            }

        case let renderableAccount as BankTransferRenderableAccount:
            handleBankTransfer(account: renderableAccount)

        default:
            break
        }
    }

    private func handleBankTransfer(account: BankTransferRenderableAccount) {
        let userActionService: UserActionService = Resolver.resolve()
        let userWalletManager: UserWalletManager = Resolver.resolve()
        guard
            account.status != .isClaimming,
            let walletPubKey = userWalletManager.wallet?.account.publicKey,
            let amount = try? account.amount
        else { return }

        let userAction = BankTransferClaimUserAction(
            id: account.id,
            accountId: account.accountId,
            token: account.token,
            amount: CurrencyFormatter(hideSymbol: true).string(for: amount),
//            fromAddress: "4iP2r5437gMF5iavTyBApSaMyYUQbtvQ1yhHm6VpnijH",
            receivingAddress: try! PublicKey.associatedTokenAddress(
                walletAddress: walletPubKey,
                tokenMintAddress: try! PublicKey(string: Token.usdc.address)
            ).base58EncodedString,
            status: .processing
        )

        // Execute and emit action.
        userActionService.execute(action: userAction)
    }

    func actionClicked(_ action: WalletActionType) {
        switch action {
        case .receive:
            guard let pubkey = try? PublicKey(string: solanaAccountsService.state.value.nativeWallet?.data.pubkey)
            else { return }
            navigation.send(.receive(publicKey: pubkey))
        case .buy:
            navigation.send(.buy)
        case .send:
            navigation.send(.send)
        case .swap:
            navigation.send(.swap)
        case .cashOut:
            navigation.send(.cashOut)
        case .topUp:
            navigation.send(.topUp)
        }
    }

    func earn() {
        navigation.send(.earn)
    }

    func scrollToTop() {
        scrollOnTheTop = true
    }

    func sellTapped() {
        navigation.send(.cashOut)
    }

    func closeBanner(id: String) {
        smallBannerVisibility = HomeBannerVisibility(id: id, closed: true)
        smallBanner = nil
        shouldCloseBanner = false
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
    func bindTransferData() {
        bankTransferService.value.state
            .filter { $0.value.userId != nil && $0.value.mobileVerified }
            .filter { [weak self] in
                // If banner with the same KYC status was already tapped, then we do not show it again
                guard let bannerVisibility = self?.smallBannerVisibility else { return true }
                return bannerVisibility.id != $0.value.kycStatus.rawValue || !bannerVisibility.closed
            }
            .map { [weak self] value -> HomeBannerParameters? in
                guard let self else { return nil  }

                if value.value.isIBANNotReady && !shouldShowErrorSubject.value {
                    self.shouldShowErrorSubject.send(true)
                }

                return HomeBannerParameters(
                    status: value.value.kycStatus,
                    action: { [weak self] in self?.requestCloseBanner(for: value.value) },
                    isLoading: false,
                    isSmallBanner: true
                )
            }
            .assignWeak(to: \.smallBanner, on: self)
            .store(in: &subscriptions)

        tappedBannerSubject
            .withLatestFrom(bankTransferService.value.state)
            .filter { !$0.isFetching }
            .receive(on: RunLoop.main)
            .sink{ [weak self] state in
                guard let self else { return }
                if state.value.isIBANNotReady {
                    self.smallBanner?.button?.isLoading = true
                    self.shouldShowErrorSubject.send(false)
                    Task { await self.bankTransferService.value.reload() }
                } else {
                    self.navigation.send(.bankTransfer)
                }
            }
            .store(in: &subscriptions)

        shouldShowErrorSubject
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.notificationService.showToast(title: "❌", text: L10n.somethingWentWrong) }
            .store(in: &subscriptions)

        bannerTapped
            .withLatestFrom(bankTransferService.value.state)
            .sink { [weak self] state in self?.requestCloseBanner(for: state.value) }
            .store(in: &subscriptions)
    }

    func requestCloseBanner(for data: UserData) {
        tappedBannerSubject.send(.bankTransfer)
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

private extension Int {
    func toCent() -> Double {
        Double(self * 10_000)
    }
}
