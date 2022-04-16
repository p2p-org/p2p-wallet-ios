//
// Created by Giang Long Tran on 12.04.2022.
//

import BECollectionView
import FeeRelayerSwift
import Foundation
import RxSwift
import SolanaSwift

extension History {
    class SceneModel: BEStreamListViewModel<SolanaSDK.ParsedTransaction> {
        private let disposeBag = DisposeBag()

        private let solanaSDK: SolanaSDK
        private let walletsRepository: WalletsRepository
        @Injected private var feeRelayer: FeeRelayerAPIClientType

        /// A list of source, where data can be fetched
        private var source: StreamSource

        init(
            solanaSDK: SolanaSDK = Resolver.resolve(),
            walletsRepository: WalletsRepository = Resolver.resolve()
        ) {
            self.solanaSDK = solanaSDK
            self.walletsRepository = walletsRepository

            let transactionRepository = CachingTransactionRepository(
                delegate: SolanaTransactionRepository(solanaSDK: solanaSDK)
            )

            let transactionParser = CachingTransactionParsing(
                delegate: DefaultTransactionParser(solanaSDK: solanaSDK, p2pFeePayers: Defaults.p2pFeePayerPubkeys)
            )

            source = MultipleAccountsStreamSource(
                sources: walletsRepository
                    .getWallets()
                    .map { wallet in
                        AccountStreamSource(
                            account: wallet.pubkey ?? "",
                            accountSymbol: wallet.token.symbol,
                            transactionRepository: transactionRepository,
                            transactionParser: transactionParser
                        )
                    }
            )

            // TODO: Remove - for testing purpose
            /*
             if let wallet = walletsRepository.nativeWallet {
                 source = AccountStreamSource(
                     account: wallet.pubkey ?? "",
                     accountSymbol: wallet.token.symbol,
                     transactionRepository: transactionRepository,
                     transactionParser: transactionParser
                 )
             }
             */

            super.init(isPaginationEnabled: true, limit: 10)
        }

        override func clear() {
            source.reset()
            super.clear()
        }

        override func next() -> Observable<[SolanaSDK.ParsedTransaction]> {
            AsyncThrowingStream<[SolanaSDK.ParsedTransaction], Error> { stream in
                Task {
                    defer { stream.finish(throwing: nil) }

                    do {
                        var receivedItem = 0
                        while true {
                            let firstTrx = try await source.first()
                            guard
                                let firstTrx = firstTrx,
                                var timeEndFilter = firstTrx.blockTime
                            else { return }

                            // Fetch next 3 days
                            timeEndFilter = timeEndFilter.addingTimeInterval(-1 * 60 * 60 * 24 * 3)

                            for try await transaction in source.next(
                                configuration: .init(timestampEnd: timeEndFilter)
                            ) {
                                stream.yield([transaction])

                                receivedItem += 1
                                if receivedItem > 10 { return }
                            }
                        }
                    } catch {
                        stream.finish(throwing: error)
                    }
                }
            }.asObservable()
        }
    }
}
