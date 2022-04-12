//
// Created by Giang Long Tran on 12.04.2022.
//

import BECollectionView
import FeeRelayerSwift
import Foundation
import RxSwift
import SolanaSwift

extension History {
    class SceneModel: BEListViewModel<SolanaSDK.ParsedTransaction> {
        private let disposeBag = DisposeBag()

        @Injected private var transactionsRepository: TransactionsRepository
        @Injected private var walletsRepository: WalletsRepository
        @Injected private var feeRelayer: FeeRelayerAPIClientType

        /// A list of source, where data can be fetched
        private var sources: [StreamSource] = []

        /// Default fetching configuration
        private let fetchingConfiguration = FetchingConfiguration(
            feePayer: Defaults.p2pFeePayerPubkeys,
            limit: 10
        )

        init() {
            super.init(isPaginationEnabled: true, limit: 10)

            sources = walletsRepository
                .getWallets()
                .map { wallet in AccountStreamSource(account: wallet.pubkey ?? "", accountSymbol: wallet.token.symbol) }
        }

        override func createRequest() -> Single<[SolanaSDK.ParsedTransaction]> {
            Single
                .zip(sources.map { source -> Single<[SolanaSDK.ParsedTransaction]> in
                    source.next(fetchingConfiguration)
                })
                .map { sourceResults -> [SolanaSDK.ParsedTransaction] in sourceResults.reduce([], +) }
                .map { transactions in transactions.unique }
        }
    }
}
