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

        let cachedTransactionRepository: CachingTransactionRepository = .init(
            delegate: SolanaTransactionRepository()
        )
        let cachedTransactionParser: CachingTransactionParsing = .init(
            delegate: DefaultTransactionParser(p2pFeePayers: Defaults.p2pFeePayerPubkeys)
        )

        /// Refresh handling
        private let refreshTriggers: [HistoryRefreshTrigger] = [
            PriceRefreshTrigger(),
            ProcessingTransactionRefreshTrigger(),
        ]

        /// A list of source, where data can be fetched
        private var source: HistoryStreamSource = EmptyStreamSource()

        /// A list of output objects, that builds, forms, maps, filters and updates a final list.
        /// This list will be delivered to UI layer.
        private let outputs: [HistoryOutput] = [
            ProcessingTransactionsOutput(),
            PriceUpdatingOutput(),
        ]

        init(
            solanaSDK: SolanaSDK = Resolver.resolve(),
            walletsRepository: WalletsRepository = Resolver.resolve()
        ) {
            self.solanaSDK = solanaSDK
            self.walletsRepository = walletsRepository

            super.init(isPaginationEnabled: true, limit: 10)

            // Register all refresh triggers
            for trigger in refreshTriggers {
                trigger.register()
                    .emit(onNext: { [weak self] in self?.refreshUI() })
                    .disposed(by: disposeBag)
            }

            // Build source
            buildSource()
        }

        func buildSource() {
            let accountStreamSources = walletsRepository
                .getWallets()
                .map { wallet in
                    AccountStreamSource(
                        account: wallet.pubkey ?? "",
                        accountSymbol: wallet.token.symbol,
                        transactionRepository: self.cachedTransactionRepository,
                        transactionParser: self.cachedTransactionParser
                    )
                }

            source = MultipleStreamSource(sources: accountStreamSources)
        }

        override func clear() {
            // Build source
            buildSource()

            // Clear cache
            cachedTransactionRepository.clear()
            cachedTransactionParser.clear()

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
                                // Skip duplicated transaction
                                if data.contains(where: { $0.signature == transaction.signature }) { continue }

                                stream.yield([transaction])

                                receivedItem += 1
                                if receivedItem > 15 { return }
                            }
                        }
                    } catch {
                        stream.finish(throwing: error)
                    }
                }
            }.asObservable()
        }

        override func map(newData: [SolanaSDK.ParsedTransaction]) -> [SolanaSDK.ParsedTransaction] {
            // Apply output transformation
            var data = newData
            for output in outputs { data = output.process(newData: data) }
            return super.map(newData: data)
        }
    }
}
