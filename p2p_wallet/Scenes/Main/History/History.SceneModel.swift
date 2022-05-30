//
// Created by Giang Long Tran on 12.04.2022.
//

import BECollectionView
import FeeRelayerSwift
import Foundation
import RxCocoa
import RxConcurrency
import RxSwift
import SolanaSwift

extension History {
    class SceneModel: BEStreamListViewModel<SolanaSDK.ParsedTransaction> {
        private let disposeBag = DisposeBag()

        private let solanaSDK: SolanaSDK
        private let walletsRepository: WalletsRepository
        @Injected private var notificationService: NotificationService

        let transactionRepository = SolanaTransactionRepository()
        let transactionParser = DefaultTransactionParser(p2pFeePayers: Defaults.p2pFeePayerPubkeys)

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

        enum State {
            case items
            case empty
            case error
        }

        var stateDriver: Driver<State> {
            Observable.combineLatest(
                stateObservable.startWith(.loading),
                dataObservable.startWith([])
                    .filter { $0 != nil }
                    .withPrevious(),
                errorRelay.startWith(false)
            ).map { state, change, error in
                if error {
                    return .error
                }

                if state == .loading || state == .initializing {
                    return .items
                } else {
                    return (change.1?.count ?? 0) > 0 ? .items : .empty
                }
            }
            .distinctUntilChanged()
            .asDriver()
        }

        let tryAgain = PublishRelay<Void>()
        private let errorRelay = PublishRelay<Bool>()

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

            tryAgain
                .subscribe(onNext: { [weak self] in
                    self?.reload()
                    self?.errorRelay.accept(false)
                })
                .disposed(by: disposeBag)
        }

        func buildSource() {
            let cachedTransactionRepository: CachingTransactionRepository = .init(
                delegate: SolanaTransactionRepository()
            )
            let cachedTransactionParser = DefaultTransactionParser(p2pFeePayers: Defaults.p2pFeePayerPubkeys)

            let accountStreamSources = walletsRepository
                .getWallets()
                .reversed()
                .map { wallet in
                    AccountStreamSource(
                        account: wallet.pubkey ?? "",
                        symbol: wallet.token.symbol,
                        transactionRepository: cachedTransactionRepository,
                        transactionParser: cachedTransactionParser
                    )
                }

            source = MultipleStreamSource(sources: accountStreamSources)
        }

        override func clear() {
            // Build source
            buildSource()

            super.clear()
        }

        override func next() -> Observable<[SolanaSDK.ParsedTransaction]> {
            AsyncThrowingStream<[HistoryStreamSource.Result], Error> { stream in
                Task {
                    defer { stream.finish(throwing: nil) }

                    var results: [HistoryStreamSource.Result] = []
                    do {
                        while true {
                            let firstTrx = try await source.first()
                            guard
                                let firstTrx = firstTrx,
                                let rawTime = firstTrx.0.blockTime
                            else {
                                stream.yield(results)
                                return
                            }

                            // Fetch next 1 days
                            var timeEndFilter = Date(timeIntervalSince1970: TimeInterval(rawTime))
                            timeEndFilter = timeEndFilter.addingTimeInterval(-1 * 60 * 60 * 24 * 1)

                            if Task.isCancelled { return }
                            for try await result in source.next(
                                configuration: .init(timestampEnd: timeEndFilter)
                            ) {
                                if Task.isCancelled { return }

                                let (signatureInfo, _, _) = result

                                // Skip duplicated transaction
                                if data.contains(where: { $0.signature == signatureInfo.signature }) { continue }
                                if results
                                    .contains(where: { $0.0.signature == signatureInfo.signature }) { continue }

                                results.append(result)

                                if results.count > 15 {
                                    stream.yield(results)
                                    return
                                }
                            }
                        }
                    } catch {
                        stream.yield(results)
                        stream.finish(throwing: error)
                    }
                }
            }
            .asObservable()
            .flatMap { results in Observable.from(results) }
            .concatMap { result in
                Observable.async { () -> [SolanaSDK.ParsedTransaction] in
                    let transactionInfo = try await self.transactionRepository
                        .getTransaction(signature: result.0.signature)
                    let transaction = try await self.transactionParser.parse(
                        signatureInfo: result.0,
                        transactionInfo: transactionInfo,
                        account: result.1,
                        symbol: result.2
                    )

                    return [transaction]
                }
            }
            .do(onError: { [weak self] error in
                DispatchQueue.main.async { [weak self] in
                    self?.errorRelay.accept(true)
                    self?.notificationService.showInAppNotification(.error(error))
                }
            })
        }

        override func join(_ newItems: [SolanaSDK.ParsedTransaction]) -> [SolanaSDK.ParsedTransaction] {
            var filteredNewData: [SolanaSDK.ParsedTransaction] = []
            for trx in newItems {
                if data.contains(where: { $0.signature == trx.signature }) { continue }
                filteredNewData.append(trx)
            }
            return data + filteredNewData
        }

        override func map(newData: [SolanaSDK.ParsedTransaction]) -> [SolanaSDK.ParsedTransaction] {
            // Apply output transformation
            var data = newData
            for output in outputs { data = output.process(newData: data) }
            return super.map(newData: data)
        }
    }
}
