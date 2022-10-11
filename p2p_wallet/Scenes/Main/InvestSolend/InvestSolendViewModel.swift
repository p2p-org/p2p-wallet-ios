// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import FeeRelayerSwift
import Resolver
import SolanaSwift
import Solend

typealias Invest = (asset: SolendConfigAsset, market: SolendMarketInfo?, userDeposit: SolendUserDeposit?)

enum InvestSolendError {
    case missingRate
}

@MainActor
class InvestSolendViewModel: ObservableObject {
    // MARK: - Services

    @Injected private var notificationService: NotificationService
    let dataService: SolendDataService
    let actionService: SolendActionService

    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Coordinator

    private let depositSubject = PassthroughSubject<SolendConfigAsset, Never>()
    var deposit: AnyPublisher<SolendConfigAsset, Never> { depositSubject.eraseToAnyPublisher() }

    private let topUpForContinueSubject = PassthroughSubject<SolendTopUpForContinueCoordinator.Model, Never>()
    var topUpForContinue: AnyPublisher<SolendTopUpForContinueCoordinator.Model, Never> {
        topUpForContinueSubject.eraseToAnyPublisher()
    }

    private let depositsSubject = PassthroughSubject<Void, Never>()
    var deposits: AnyPublisher<Void, Never> { depositsSubject.eraseToAnyPublisher() }

    // MARK: - State

    @Published var loading: Bool = false
    @Published var invests: [Invest] = []
    @Published var bannerError: InvestSolendError?
    var apyLoaded: Bool { invests.contains { $0.market != nil } }

    var isTutorialShown: Bool {
        Defaults.isSolendTutorialShown
    }

    // MARK: - Init

    init(dataService: SolendDataService = Resolver.resolve(), actionService: SolendActionService = Resolver.resolve()) {
        self.dataService = dataService
        self.actionService = actionService

        // Updating data service depends on action service
        actionService.currentAction
            .filter { (action: SolendAction?) -> Bool in
                guard let action = action else { return false }
                switch action.status {
                case .processing: return false
                case .success, .failed: return true
                }
            }
            .sink { [dataService] _ in
                Task.detached {
                    dataService.clearDeposits()
                    try await dataService.update()
                }
                Task.detached {
                    Resolver.resolve(WalletsRepository.self).reload()
                }
            }
            .store(in: &subscriptions)

        // Displaying notification
        actionService.currentAction
            .sink { [weak self] (action: SolendAction?) in
                guard let action = action else { return }
                if action.status == .success {
                    switch action.type {
                    case .deposit:
                        self?.notificationService
                            .showInAppNotification(.done(L10n.theFundsHaveBeenDepositedSuccessfully))
                    case .withdraw:
                        self?.notificationService
                            .showInAppNotification(.done(L10n.theFundsHaveBeenWithdrawnSuccessfully))
                    }
                }
            }
            .store(in: &subscriptions)

        // Display error when rate is missing
        dataService.marketInfo
            .receive(on: RunLoop.main)
            .sink { [weak self] (marketInfo: [SolendMarketInfo]?) in
                self?.bannerError = marketInfo == nil ? .missingRate : nil
            }.store(in: &subscriptions)

        // Process data from data service
        dataService.availableAssets
            .combineLatest(dataService.marketInfo, dataService.deposits)
            .map { (assets: [SolendConfigAsset]?, marketInfo: [SolendMarketInfo]?, userDeposits: [SolendUserDeposit]?) -> [Invest] in
                guard let assets = assets else { return [] }
                return assets.map { asset -> Invest in
                    (
                        asset: asset,
                        market: marketInfo?.first(where: { $0.symbol == asset.symbol }),
                        userDeposit: userDeposits?.first(where: { $0.symbol == asset.symbol })
                    )
                }.sorted { (v1: Invest, v2: Invest) -> Bool in
                    let apy1: Double = .init(v1.market?.supplyInterest ?? "") ?? 0
                    let apy2: Double = .init(v2.market?.supplyInterest ?? "") ?? 0
                    return apy1 > apy2
                }
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] value in self?.invests = value }
            .store(in: &subscriptions)

        /// Mapping status to loading var
        dataService.status
            .combineLatest(dataService.deposits, dataService.error)
            .map { status, deposits, error in
                if error != nil { return false }
                if deposits == nil { return true }

                switch status {
                case .initialized, .ready: return false
                case .updating: return true
                }
            }
            .receive(on: RunLoop.main)
            .assign(to: \.loading, on: self)
            .store(in: &subscriptions)

        Task { try await update() }
    }

    // MARK: - Actions

    /// Request new data for data service
    func update() async throws {
        try await dataService.update()
    }

    /// Show user's deposits
    func showDeposits() {
        depositsSubject.send()
    }

    /// User clicks invest
    func assetClicked(_ asset: SolendConfigAsset, market _: SolendMarketInfo?) {
        guard InvestSolendHelper.readyToStartAction(notificationService, actionService.getCurrentAction()) == true
        else {
            return
        }

        let wallets: WalletsRepository = Resolver.resolve()

        // Get user token account
        let tokenAccount: Wallet? = wallets
            .getWallets()
            .first(where: { (wallet: Wallet) -> Bool in asset.mintAddress == wallet.mintAddress })

        if (tokenAccount?.amount ?? 0) > 0 {
            // User has this token for deposit
            depositSubject.send(asset)
        } else {
            // Check user has another token to deposit
            let hasAnotherToken: Bool = wallets.getWallets().first(where: { ($0.lamports ?? 0) > 0 }) != nil
            topUpForContinueSubject.send(.init(
                asset: asset,
                strategy: hasAnotherToken ? .withoutOnlyTokenForDeposit : .withoutAnyTokens
            ))
        }
    }
}
