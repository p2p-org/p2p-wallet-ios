// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Resolver
import SolanaPricesAPIs
import Solend

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
                if let action = action {
                    return Just(self.actionState(action: action)).eraseToAnyPublisher()
                } else {
                    return self.dataService.availableAssets
                        .combineLatest(
                            self.dataService.deposits,
                            self.dataService.marketInfo,
                            self.dataService.lastUpdateDate
                        )
                        .combineLatest(
                            self.dataService.error,
                            self.dataService.status
                        )
                        .map { ($0.0.0, $0.0.1, $0.0.2, $0.0.3, $0.1, $0.2) }
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

    private func actionState(action: SolendAction) -> InvestSolendBannerState {
        switch action.status {
        case let .failed(msg):
            switch action.type {
            case .deposit:
                return .failure(
                    title: L10n.depositingFundsFailed,
                    subtitle: L10n.TheFundsAreReturnedToYourWallet.youCanTryDepositingAgain
                )
            case .withdraw:
                return .failure(
                    title: L10n.anUnexpectedErrorOccurred,
                    subtitle: L10n.DonTWorryYourDepositsAreSafe.somehowWithdrawalDidNotHappen
                )
            }

        default:
            return .processingAction
        }
    }

    private func dataState(
        assets: [SolendConfigAsset]?,
        deposits: [SolendUserDeposit]?,
        marketInfos: [SolendMarketInfo]?,
        lastUpdate: Date,
        error: Error?,
        status: SolendDataStatus
    ) -> InvestSolendBannerState {
        if error != nil {
            return .failure(
                title: L10n.anUnexpectedErrorOccurred,
                subtitle: L10n.DonTWorryYourDepositsAreSafe.weJustHaveIssuesWithShowingTheInfo
            )
        }
        // assets is loading
        switch status {
        case .updating:
            return .pending
        default:
            break
        }

        // Sure market info is available
        guard let assets = assets, let deposits = deposits, let marketInfos = marketInfos else {
            return .failure(
                title: L10n.anUnexpectedErrorOccurred,
                subtitle: L10n.DonTWorryYourDepositsAreSafe.weJustHaveIssuesWithShowingTheInfo
            )
        }

        // no assets
        if deposits.isEmpty {
            return .learnMore
        }

        // combine assets
        let urls = assets
            .filter { asset in deposits.contains(where: { $0.symbol == asset.symbol }) }
            .map { asset -> URL? in URL(string: asset.logo ?? "") }
            .compactMap { $0 }

        // Calculate current balance
        let total = calculateBalance(assets: assets, deposits: deposits)

        let reward = calculateReward(marketInfos: marketInfos, userDeposits: deposits)
        return .withBalance(model: .init(
            balance: total,
            lastUpdate: lastUpdate,
            reward: reward,
            depositUrls: urls
        ))
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
}

// MARK: - State

extension InvestSolendBannerViewModel {
    enum InvestSolendBannerError: Equatable {
        case fetchError
        case actionError
    }

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
