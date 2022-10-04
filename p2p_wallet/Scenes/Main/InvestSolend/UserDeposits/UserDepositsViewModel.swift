// // Copyright 2022 P2P Validator Authors. All rights reserved.
// // Use of this source code is governed by a MIT-style license that can be
// // found in the LICENSE file.
//
// import Combine
// import Foundation
// import Resolver
// import Solend
//
// @MainActor
// class UserDepositsViewModel: ObservableObject {
//     typealias Deposit = (asset: SolendConfigAsset, market: SolendMarketInfo?, userDeposit: SolendUserDeposit?)
//
//     private let dataService: SolendDataService
//     private var subscriptions = Set<AnyCancellable>()
//
//     @Published var deposits: [Deposit] = []
//
//     init(dataService: SolendDataService? = nil) {
//         self.dataService = dataService ?? Resolver.resolve(SolendDataService.self)
//
//         /// Process data from data service
//         self.dataService.availableAssets
//             .combineLatest(self.dataService.marketInfo, self.dataService.deposits)
//             .map { (assets: [SolendConfigAsset]?, marketInfo: [SolendMarketInfo]?, userDeposits: [SolendUserDeposit]?) -> [Deposit] in
//                 guard let assets = assets else { return [] }
//                 return assets
//                     .filter { asset -> Bool in
//                         userDeposits?.contains { $0.symbol == asset.symbol } ?? false
//                     }
//                     .map { asset -> Deposit in
//                         (
//                             asset: asset,
//                             market: marketInfo?.first(where: { $0.symbol == asset.symbol }),
//                             userDeposit: userDeposits?.first(where: { $0.symbol == asset.symbol })
//                         )
//                     }.sorted { (v1: Deposit, v2: Deposit) -> Bool in
//                         let apy1: Double = .init(v1.market?.supplyInterest ?? "") ?? 0
//                         let apy2: Double = .init(v2.market?.supplyInterest ?? "") ?? 0
//                         return apy1 > apy2
//                     }
//             }
//             .receive(on: RunLoop.main)
//             .sink { [weak self] value in self?.deposits = value }
//             .store(in: &subscriptions)
//     }
// }
