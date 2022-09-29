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
    private let solendService: SolendDataService

    init(mocked: Bool = false) {
        solendService = mocked ? SolendDataServiceMock() : Resolver.resolve(SolendDataService.self)

        solendService.availableAssets
            .combineLatest(solendService.deposits)
            .sink(receiveValue: { [weak self] (assets: [SolendConfigAsset]?, deposits: [SolendUserDeposit]?) in
                self?.state = .learnMore

                guard let assets = assets else {
                    self?.state = .failure(title: L10n.somethingWentWrong, subtitle: L10n.pleaseTryAgainLater)
                    return
                }

                guard let deposits = deposits else {
                    self?.state = .learnMore
                    return
                }

                if deposits.isEmpty {
                    self?.state = .learnMore
                } else {
                    let urls = assets
                        .map { asset -> URL? in URL(string: asset.logo ?? "") }
                        .compactMap { $0 }

                    let total = self?.calculateBalance(assets: assets, deposits: deposits) ?? 0
                    self?.state = .withBalance(model: .init(
                        balance: "$ \(total.fixedDecimal(9))",
                        depositUrls: urls
                    ))
                }
            })
            .store(in: &cancellables)
    }

    func calculateBalance(assets: [SolendConfigAsset], deposits: [SolendUserDeposit]) -> Double {
        deposits
            .map { (deposit: SolendUserDeposit) -> (amount: Double, symbol: String) in
                (deposit.depositedAmount.double ?? 0, deposit.symbol)
            }
            .map { [priceService] (amount: Double, symbol: String) -> Double in
                guard let asset: SolendConfigAsset = assets.first(where: { $0.symbol == symbol }) else { return 0 }
                let currentPrice = priceService.currentPrice(for: symbol)?.value ?? 0
                return currentPrice * amount
            }
            .reduce(0, +)
    }
}

// MARK: - State

extension InvestSolendBannerViewModel {
    enum InvestSolendBannerState {
        case pending
        case failure(title: String, subtitle: String)
        case learnMore
        case withBalance(model: InvestSolendBannerBalanceModel)

        var notLearnMode: Bool {
            switch self {
            case .pending, .failure, .withBalance:
                return true
            case .learnMore:
                return false
            }
        }
    }

    struct InvestSolendBannerBalanceModel {
        let balance: String
        let depositUrls: [URL]
    }
}
