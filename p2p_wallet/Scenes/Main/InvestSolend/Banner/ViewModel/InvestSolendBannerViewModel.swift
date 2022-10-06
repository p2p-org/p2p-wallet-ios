// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Resolver
import Solend
import SolanaPricesAPIs

class InvestSolendBannerViewModel: ObservableObject {
    @Injected private var priceService: PricesServiceType

    @Published var state: InvestSolendBannerState = .pending

    private var cancellables = Set<AnyCancellable>()
    private let dataService: SolendDataService
    private let actionService: SolendActionService

    init(
        dataService: SolendDataService? = nil,
        actionService: SolendActionService? = nil
    ) {
        self.dataService = dataService ?? Resolver.resolve(SolendDataService.self)
        self.actionService = actionService ?? Resolver.resolve(SolendActionService.self)

        self.actionService.currentAction
            .removeDuplicates()
            .flatMap { [weak self] action -> AnyPublisher<InvestSolendBannerState, Never> in
                guard let self = self else { return CurrentValueSubject(.pending).eraseToAnyPublisher() }
                if action != nil {
                    return Just(.processingAction).eraseToAnyPublisher()
                } else {
                    return self.dataService.availableAssets
                        .combineLatest(
                            self.dataService.deposits,
                            self.dataService.marketInfo,
                            self.dataService.lastUpdateDate
                        )
                        .map(self.dataState)
                        .removeDuplicates()
                        .eraseToAnyPublisher()
                }
            }
            .receive(on: RunLoop.main)
            .removeDuplicates()
            .assign(to: \.state, on: self)
            .store(in: &cancellables)
    }

    private func dataState(assets: [SolendConfigAsset]?,deposits: [SolendUserDeposit]?, marketInfos: [SolendMarketInfo]?, lastUpdate: Date) -> InvestSolendBannerState {
        // assets is loading
        guard let assets = assets, let deposits = deposits else {
            return .pending
        }

        // no assets
        if deposits.isEmpty {
            return .learnMore
        }

        // combine assets
        let urls = assets
            .map { asset -> URL? in URL(string: asset.logo ?? "") }
            .compactMap { $0 }

        // Calculate current balance
        let total = calculateBalance(assets: assets, deposits: deposits)
        
        let reward: Double
        if let marketInfos = marketInfos {
            // Calculate reward rate
            reward = calculateReward(marketInfos: marketInfos, userDeposits: deposits)
        } else {
            reward = 0
        }
        
        return .withBalance(model: .init(
            balance: total,
            lastUpdate: lastUpdate,
            reward: reward,
            depositUrls: urls
        ))
    }

    private func actionState(action _: SolendAction) -> InvestSolendBannerState {
        .processingAction
    }
    
    func calculateReward(marketInfos: [SolendMarketInfo], userDeposits: [SolendUserDeposit]) -> Double {
        let rewards = SolendMath.reward(marketInfos: marketInfos, userDeposits: userDeposits)
        return rewards
            .map { [priceService] (reward: SolendMath.Reward) -> Double in
                let price = priceService.currentPrice(for: reward.symbol)?.value ?? 0.0
                return reward.rate * price
            }
            .reduce(0, +)
    }

    private func calculateBalance(assets _: [SolendConfigAsset], deposits: [SolendUserDeposit]) -> Double {
        deposits
            .map { (deposit: SolendUserDeposit) -> (amount: Double, symbol: String) in
                (deposit.depositedAmount.double ?? 0, deposit.symbol)
            }
            .map { [priceService] (amount: Double, symbol: String) -> Double in
                let currentPrice = priceService.currentPrice(for: symbol)?.value ?? 0
                return currentPrice * amount
            }
            .reduce(0, +)
    }

    func update() async throws {
        try await dataService.update()
    }
}

// MARK: - State

extension InvestSolendBannerViewModel {
    enum InvestSolendBannerState: Equatable {
        case pending
        case failure(title: String, subtitle: String)
        case learnMore
        case processingAction
        case withBalance(model: InvestSolendBannerBalanceModel)

        var notLearnMode: Bool {
            switch self {
            case .pending, .failure, .withBalance, .processingAction:
                return true
            case .learnMore:
                return false
            }
        }
    }

    struct InvestSolendBannerBalanceModel: Equatable {
        let balance: Double
        let lastUpdate: Date
        let reward: Double
        let depositUrls: [URL]
    }
}
