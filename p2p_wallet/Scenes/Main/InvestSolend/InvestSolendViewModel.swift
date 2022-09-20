// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import FeeRelayerSwift
import Resolver
import SolanaSwift
import Solend

typealias Invest = (asset: SolendConfigAsset, market: SolendMarketInfo?, userDeposit: SolendUserDeposit?)

@MainActor
class InvestSolendViewModel: ObservableObject {
    private let service: SolendDataService
    var subscriptions = Set<AnyCancellable>()

    @Published var loading: Bool = false
    @Published var market: [Invest] = []
    @Published var totalDeposit: Double = 0
    @Published var isPresentingTutorial = false

    init(mocked: Bool) throws {
        service = mocked ? SolendDataServiceMock() : Resolver.resolve(SolendDataService.self)

        service.availableAssets
            .combineLatest(service.marketInfo, service.deposits)
            .map { (assets: [SolendConfigAsset], marketInfo: [SolendMarketInfo], userDeposits: [SolendUserDeposit]) -> [Invest] in
                assets.map { asset -> Invest in
                    (
                        asset: asset,
                        market: marketInfo.first(where: { $0.symbol == asset.symbol }),
                        userDeposit: userDeposits.first(where: { $0.symbol == asset.symbol })
                    )
                }.sorted { (v1: Invest, v2: Invest) -> Bool in
                    let apy1: Double = .init(v1.market?.supplyInterest ?? "") ?? 0
                    let apy2: Double = .init(v2.market?.supplyInterest ?? "") ?? 0
                    return apy1 > apy2
                }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in self?.market = value }
            .store(in: &subscriptions)

        service.deposits
            .map { deposits -> Double in
                deposits.reduce(0) { (partialResult: Double, deposit: SolendUserDeposit) in
                    partialResult + (Double(deposit.depositedAmount) ?? 0)
                }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (totalDeposit: Double) in
                self?.totalDeposit = totalDeposit
            }
            .store(in: &subscriptions)

        service.status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                switch status {
                case .initialized, .ready: self.loading = false
                case .updating: self.loading = true
                }
            }
            .store(in: &subscriptions)
    }

    func update() async throws {
        try await service.update()
    }
}
