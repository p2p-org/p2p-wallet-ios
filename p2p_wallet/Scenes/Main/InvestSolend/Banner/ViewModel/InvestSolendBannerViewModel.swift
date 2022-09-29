// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Resolver
import Solend

class InvestSolendBannerViewModel: ObservableObject {
    @Published var state: InvestSolendBannerState = .pending

    private var cancellables = Set<AnyCancellable>()
    private let solendService: SolendDataService

    init(mocked: Bool = true) {
        solendService = mocked ? SolendDataServiceMock() : Resolver.resolve(SolendDataService.self)

        solendService.availableAssets
            .combineLatest(solendService.deposits)
            .sink(receiveValue: { [weak self] assets, deposits in
                self?.state = .learnMore
                if deposits.isEmpty {
                    self?.state = .learnMore
                } else {
                    let urls = assets.map { asset -> URL? in
                        var asset = asset
                        if asset.symbol == "USDT" {
                            asset = .init(
                                name: asset.name,
                                symbol: asset.symbol,
                                decimals: asset.decimals,
                                mintAddress: asset.mintAddress,
                                logo: "https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/BQcdHdAQW1hczDbBi9hiegXAR7A98Q9jx3X3iBBBDiq4/logo.png"
                            )
                        }
                        return URL(string: asset.logo ?? "")
                    }.compactMap { $0 }
                    self?.state = .withBalance(model: .init(
                        balance: "$89.5762413036",
                        depositUrls: urls
                    ))
                }
            })
            .store(in: &cancellables)
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
