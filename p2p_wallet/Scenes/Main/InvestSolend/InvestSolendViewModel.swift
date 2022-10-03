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
    private let service: SolendDataService
    @Injected private var wallets: WalletsRepository

    private var subscriptions = Set<AnyCancellable>()

    private let depositSubject = PassthroughSubject<SolendConfigAsset, Never>()
    var deposit: AnyPublisher<SolendConfigAsset, Never> { depositSubject.eraseToAnyPublisher() }
    private let topUpForContinueSubject = PassthroughSubject<SolendTopUpForContinueCoordinator.Model, Never>()
    var topUpForContinue: AnyPublisher<SolendTopUpForContinueCoordinator.Model, Never> {
        topUpForContinueSubject.eraseToAnyPublisher()
    }

    @Published var loading: Bool = false
    @Published var market: [Invest] = []
    @Published var totalDeposit: Double = 0

    @Published var bannerError: InvestSolendError?

    var isTutorialShown: Bool {
        Defaults.isSolendTutorialShown
    }

    init(mocked: Bool = false) {
        service = mocked ? SolendDataServiceMock() : Resolver.resolve(SolendDataService.self)

        service.marketInfo
            .receive(on: RunLoop.main)
            .sink { [weak self] (marketInfo: [SolendMarketInfo]?) in
                self?.bannerError = marketInfo == nil ? .missingRate : nil
            }.store(in: &subscriptions)

        service.availableAssets
            .combineLatest(service.marketInfo, service.deposits)
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
            .sink { [weak self] value in self?.market = value }
            .store(in: &subscriptions)

        service.deposits
            .map { deposits -> Double in
                guard let deposits = deposits else { return 0 }

                return deposits.reduce(0) { (partialResult: Double, deposit: SolendUserDeposit) in
                    partialResult + (Double(deposit.depositedAmount) ?? 0)
                }
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] (totalDeposit: Double) in
                self?.totalDeposit = totalDeposit
            }
            .store(in: &subscriptions)

        service.status
            .map { status in
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

    func update() async throws {
        try await service.update()
    }

    func assetClicked(_ asset: SolendConfigAsset, market: SolendMarketInfo?) {
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
                apy: Double(market?.supplyInterest ?? ""),
                strategy: hasAnotherToken ? .withoutOnlyTokenForDeposit : .withoutAnyTokens
            ))
        }
    }
}
