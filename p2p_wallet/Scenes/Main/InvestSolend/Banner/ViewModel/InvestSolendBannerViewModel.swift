// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Resolver
import Solend

class InvestSolendBannerViewModel: ObservableObject {
    @Injected private var priceService: PricesServiceType

    @Published var state: InvestSolendBannerState = .pending

    private var cancellables = Set<AnyCancellable>()
    private let dataService: SolendDataService
    private let actionService: SolendActionService

    init(dataService: SolendDataService? = nil, actionService: SolendActionService? = nil) {
        self.dataService = dataService ?? Resolver.resolve(SolendDataService.self)
        self.actionService = actionService ?? Resolver.resolve(SolendActionService.self)

        self.dataService.availableAssets
            .combineLatest(self.dataService.deposits, self.actionService.currentAction)
            .map { [weak self] (assets: [SolendConfigAsset]?, userDeposits: [SolendUserDeposit]?, action: SolendAction?) in
                self?.stateMapping(assets: assets, deposits: userDeposits, action: action) ?? .pending
            }
            .receive(on: RunLoop.main)
            .removeDuplicates()
            .assign(to: \.state, on: self)
            .store(in: &cancellables)
    }

    func stateMapping(
        assets: [SolendConfigAsset]?,
        deposits: [SolendUserDeposit]?,
        action: SolendAction?
    ) -> InvestSolendBannerState {
        if let action = action {
            return actionState(action: action)
        } else {
            return dataState(assets: assets, deposits: deposits)
        }
    }

    private func dataState(assets: [SolendConfigAsset]?, deposits: [SolendUserDeposit]?) -> InvestSolendBannerState {
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

        let total = calculateBalance(assets: assets, deposits: deposits) ?? 0
        return .withBalance(model: .init(
            balance: "$ \(total.fixedDecimal(9))",
            depositUrls: urls
        ))
    }

    private func actionState(action _: SolendAction) -> InvestSolendBannerState {
        .processingAction
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
        let balance: String
        let depositUrls: [URL]
    }
}
