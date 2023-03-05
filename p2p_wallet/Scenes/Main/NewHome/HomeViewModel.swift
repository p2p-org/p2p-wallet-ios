//
//  HomeViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 08.08.2022.
//

import AnalyticsManager
import Combine
import Foundation
import Resolver
import Sell
import SolanaSwift

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Dependencies

    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var clipboardManager: ClipboardManagerType
    @Injected private var solanaTracker: SolanaTracker
    @Injected private var notificationsService: NotificationService
    @Injected private var accountStorage: AccountStorageType
    @Injected private var nameStorage: NameStorageType
    @Injected private var createNameService: CreateNameService
    @Injected private var solanaAccountsManager: SolanaAccountsManager
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
        reload()
    }

    // MARK: - Methods

    func reload() {
        Task {
            try await solanaAccountsManager.fetch()
        }
    }

    func copyToClipboard() {
        clipboardManager.copyToClipboard(solanaAccountsManager.state.item.nativeWallet?.data.pubkey ?? "")
        notificationsService.showToast(title: "🖤", text: L10n.addressWasCopiedToClipboard, haptic: true)
        analyticsManager.log(event: .mainCopyAddress)
    }

    func updateAddressIfNeeded() {
        if let name = nameStorage.getName(), !name.isEmpty {
            address = "\(name).key"
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

        // isInitialized
        solanaAccountsManager
            .$state
            .map { $0.status != .initializing }
            .weakAssign(to: \.isInitialized, on: self)
            .store(in: &subscriptions)

        // state, address, error, log
        solanaAccountsManager
            .$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                guard let self else { return }

                // accumulate total amount
                let fiatAmount = state.item.totalAmountInCurrentFiat
                let isEmpty = fiatAmount <= 0

                // address
                self.updateAddressIfNeeded()

                switch state.status {
                case .initializing:
                    self.state = .pending
                default:
                    self.state = isEmpty ? .empty : .withTokens

                    // log
                    self.analyticsManager.log(parameter: .userHasPositiveBalance(!isEmpty))
                    self.analyticsManager.log(parameter: .userAggregateBalance(fiatAmount))
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
