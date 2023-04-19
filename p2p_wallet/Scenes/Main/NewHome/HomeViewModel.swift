//
//  HomeViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 08.08.2022.
//

import AnalyticsManager
import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import Sell
import Send
import SolanaSwift
import Wormhole

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Dependencies

    @Injected private var solanaAccountsService: SolanaAccountsService
    @Injected private var ethereumAccountsService: EthereumAccountsService

    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var clipboardManager: ClipboardManagerType
    @Injected private var solanaTracker: SolanaTracker
    @Injected private var notificationsService: NotificationService
    @Injected private var accountStorage: AccountStorageType
    @Injected private var nameStorage: NameStorageType
    @Injected private var createNameService: CreateNameService
    @Injected private var sellDataService: any SellDataService

    // MARK: - Published properties

    @Published var state = State.pending
    @Published var address = ""

    // MARK: - Properties

    private var subscriptions = Set<AnyCancellable>()
    private var isInitialized = false

    // MARK: - Initializers

    init() {
        // bind
        bind()

        // reload
        Task { await reload() }
    }

    // MARK: - Methods

    func reload() async {
        await HomeAccountsSynchronisationService().refresh()
    }

    func copyToClipboard() {
        clipboardManager.copyToClipboard(solanaAccountsService.state.value.nativeWallet?.data.pubkey ?? "")
        notificationsService.showToast(title: "🖤", text: L10n.addressWasCopiedToClipboard, haptic: true)
        analyticsManager.log(event: .mainCopyAddress)
    }

    func updateAddressIfNeeded() {
        if let name = nameStorage.getName(), !name.isEmpty {
            address = name
        } else if let address = accountStorage.account?.publicKey.base58EncodedString.shortAddress {
            self.address = address
        }
    }

    func viewAppeared() {
        if available(.solanaNegativeStatus) {
            solanaTracker.startTracking()
        }

        analyticsManager.log(
            event: .mainScreenWalletsOpen(isSellEnabled: sellDataService.isAvailable)
        )
    }
}

private extension HomeViewModel {
    func bind() {
        // Monitor solana network
        if available(.solanaNegativeStatus) {
            solanaTracker.unstableSolana
                .sink { [weak self] in
                    self?.notificationsService.showToast(
                        title: "😴",
                        text: L10n.solanaHasSomeProblems,
                        withAutoHidden: false
                    )
                }
                .store(in: &subscriptions)
        }

        // Monitor user action
        let userActionService: UserActionService = Resolver.resolve()
        userActionService
            .$actions
            .withPrevious()
            .sink { [weak self] prev, next in
                for updatedUserAction in next {
                    if let oldUserAction = prev?.first(where: { $0.id == updatedUserAction.id }) {
                        // Status if different
                        guard oldUserAction.status != updatedUserAction.status else { continue }

                        // Claiming
                        if case .error = updatedUserAction.status {
                            if updatedUserAction is WormholeClaimUserAction {
                                self?.notificationsService
                                    .showInAppNotification(.error(L10n.ThereWasAProblemWithClaiming.pleaseTryAgain))
                            }
                        }

                        // Sending
                        if case .error = updatedUserAction.status {
                            switch updatedUserAction {
                            case is WormholeClaimUserAction:
                                self?.notificationsService
                                    .showInAppNotification(.error(L10n.ThereWasAProblemWithClaiming.pleaseTryAgain))
                            case is WormholeSendUserAction:
                                self?.notificationsService
                                    .showInAppNotification(.error(L10n.ThereWasAProblemWithSending.pleaseTryAgain))
                            default:
                                break
                            }
                        }
                    }
                }
            }
            .store(in: &subscriptions)

        // Check if accounts managers was initialized.
        let solanaInitialization = solanaAccountsService
            .$state
            .map { $0.status != .initializing }

        let ethereumInitialization = ethereumAccountsService
            .$state
            .map { $0.status != .initializing }

        // Merge two services.
        Publishers
            .CombineLatest(solanaInitialization, ethereumInitialization)
            .map { $0 && $1 }
            .assignWeak(to: \.isInitialized, on: self)
            .store(in: &subscriptions)

        // state, address, error, log

        Publishers
            .CombineLatest(solanaAccountsService.$state, ethereumAccountsService.$state)
            .receive(on: RunLoop.main)
            .sink { [weak self] solanaState, ethereumState in
                guard let self else { return }

                let solanaTotalBalance = solanaState.value.reduce(into: 0) { partialResult, account in
                    partialResult = partialResult + account.amountInFiatDouble
                }

                let hasAnyTokenWithPositiveBalance =
                    solanaState.value.contains(where: { account in (account.data.lamports ?? 0) > 0 }) ||
                    ethereumState.value.contains(where: { account in account.balance > 0 })

                // TODO: Bad place
                self.updateAddressIfNeeded()

                // Merge two status
                let mergedStatus = AsynValueStatus.combine(lhs: solanaState.status, rhs: ethereumState.status)

                switch mergedStatus {
                case .initializing:
                    self.state = .pending
                default:
                    self.state = hasAnyTokenWithPositiveBalance ? .withTokens : .empty

                    // log
                    self.analyticsManager.log(parameter: .userHasPositiveBalance(solanaTotalBalance > 0))
                    self.analyticsManager.log(parameter: .userAggregateBalance(solanaTotalBalance))
                }
            }
            .store(in: &subscriptions)

        // update name when needed
        createNameService.createNameResult
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSuccess in
                guard isSuccess else { return }
                self?.updateAddressIfNeeded()
            }
            .store(in: &subscriptions)
    }
}

// MARK: - Nested types

extension HomeViewModel {
    enum State {
        case pending
        case withTokens
        case empty
    }
}

// MARK: - Helpers

private extension String {
    var shortAddress: String {
        "\(prefix(4))...\(suffix(4))"
    }
}
