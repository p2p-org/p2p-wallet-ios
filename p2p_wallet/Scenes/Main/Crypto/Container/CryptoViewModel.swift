//
//  CryptoViewModel.swift
//  p2p_wallet
//
//  Created by Zafar Ivaev on 12/07/23.
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

/// ViewModel of `Crypto` scene
final class CryptoViewModel: BaseViewModel, ObservableObject {

    // MARK: - Properties
    
    @Injected private var solanaAccountsService: SolanaAccountsService
    @Injected private var ethereumAccountsService: EthereumAccountsService

    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var clipboardManager: ClipboardManagerType
    @Injected private var solanaTracker: SolanaTracker
    @Injected private var notificationsService: NotificationService
    @Injected private var accountStorage: AccountStorageType
    @Injected private var nameStorage: NameStorageType
    @Injected private var sellDataService: any SellDataService
    
    @Published private(set) var balance: String = "0"
    @Published private(set) var actions: [WalletActionType] = [.receive, .swap]
    
    @Published var state = State.pending
    
    private var isInitialized = false
    
    /// Navigation subject (passed from Coordinator)
    let navigation: PassthroughSubject<CryptoNavigation, Never>
    
    // MARK: - Initializers
    
    init(navigation: PassthroughSubject<CryptoNavigation, Never>) {
        self.navigation = navigation
        super.init()
        
        // bind
        bind()

        // reload
        Task { await reload() }
    }
    
    // MARK: - Methods

    func reload() async {
        await CryptoAccountsSynchronizationService().refresh()
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

private extension CryptoViewModel {
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
            .statePublisher
            .map { $0.status != .initializing }

        let ethereumInitialization = ethereumAccountsService
            .statePublisher
            .map { $0.status != .initializing }

        // Merge two services.
        Publishers
            .CombineLatest(solanaInitialization, ethereumInitialization)
            .map { $0 && $1 }
            .assignWeak(to: \.isInitialized, on: self)
            .store(in: &subscriptions)

        // state, error, log

        Publishers
            .CombineLatest(solanaAccountsService.statePublisher, ethereumAccountsService.statePublisher)
            .receive(on: RunLoop.main)
            .sink { [weak self] solanaState, ethereumState in
                guard let self else { return }

                let solanaTotalBalance = solanaState.value.reduce(into: 0) { partialResult, account in
                    partialResult = partialResult + account.amountInFiatDouble
                }

                let hasAnyTokenWithPositiveBalance =
                    solanaState.value.contains(where: { account in (account.data.lamports ?? 0) > 0 }) ||
                    ethereumState.value.contains(where: { account in account.balance > 0 })

                // Merge two status
                let mergedStatus = AsynValueStatus.combine(lhs: solanaState.status, rhs: ethereumState.status)

                switch mergedStatus {
                case .initializing:
                    self.state = .pending
                default:
                    self.state = hasAnyTokenWithPositiveBalance ? .accounts : .empty

                    // log
                    self.analyticsManager.log(parameter: .userHasPositiveBalance(solanaTotalBalance > 0))
                    self.analyticsManager.log(parameter: .userAggregateBalance(solanaTotalBalance))
                }
            }
            .store(in: &subscriptions)
    }
}

// MARK: - Nested Types

extension CryptoViewModel {
    enum State {
        case pending
        case empty
        case accounts
    }
}

// MARK: - Helpers

private extension String {
    var shortAddress: String {
        "\(prefix(4))...\(suffix(4))"
    }
}
