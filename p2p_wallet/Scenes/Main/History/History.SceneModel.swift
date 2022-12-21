//
// Created by Giang Long Tran on 12.04.2022.
//

import BECollectionView
import Combine
import FeeRelayerSwift
import Foundation
import History
import Resolver
import RxCocoa
import RxConcurrency
import RxSwift
import SolanaSwift
import TransactionParser

extension History {
    class SceneModel: BEStreamListViewModel<HistoryItem> {
        typealias AccountSymbol = (account: String, symbol: String)

        // MARK: - Dependencies

        @Injected private var walletsRepository: WalletsRepository
        @Injected private var notificationService: NotificationService
        let transactionRepository = SolanaTransactionRepository(solanaAPIClient: Resolver.resolve())
        @Injected private var transactionParserRepository: TransactionParsedRepository
        @Injected private var sellDataService: any SellDataService

        // MARK: - Properties

        public let onTapPublisher: PassthroughSubject<HistoryItem, Never> = .init()
        private let disposeBag = DisposeBag()

        /// Symbol to filter coins
        let accountSymbol: AccountSymbol?

        /// Refresh handling
        private var refreshTriggers: [HistoryRefreshTrigger]

        /// A list of source, where data can be fetched
        private var source: HistoryStreamSource = EmptyStreamSource()

        /// A list of output objects, that builds, forms, maps, filters and updates a final list.
        /// This list will be delivered to UI layer.
        private var outputs: [HistoryOutput]

        enum State {
            case items
            case empty
            case error
        }

        var stateDriver: Driver<State> {
            Observable.combineLatest(
                dataObservable.startWith([])
                    .filter { $0 != nil }
                    .withPrevious(),
                stateObservable.startWith(.loading),
                errorRelay.startWith(false)
            ).map { change, state, error in
                if error { return .error }

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
        let refreshPage = PublishRelay<Void>()
        private let errorRelay = PublishRelay<Bool>()

        init(accountSymbol: AccountSymbol? = nil) {
            self.accountSymbol = accountSymbol

            // Output
            var outputs: [HistoryOutput] = [
                ProcessingTransactionsOutput(accountFilter: accountSymbol?.account),
                PriceUpdatingOutput(),
            ]

            // Refresh trigger
            var refreshTriggers: [HistoryRefreshTrigger] = [
                PriceRefreshTrigger(),
                ProcessingTransactionRefreshTrigger(),
            ]

            if accountSymbol == nil {
                outputs.append(SellTransactionsOutput())
                refreshTriggers.append(SellTransactionsRefreshTrigger())
            }

            self.outputs = outputs
            self.refreshTriggers = refreshTriggers

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
            refreshPage
                .subscribe(onNext: { [weak self] in
                    self?.reload()
                })
                .disposed(by: disposeBag)
        }

        func buildSource() {
            let transactionRepository = SolanaTransactionRepository(solanaAPIClient: Resolver.resolve())

            if let accountSymbol = accountSymbol {
                source = AccountStreamSource(
                    account: accountSymbol.account,
                    symbol: accountSymbol.symbol,
                    transactionRepository: transactionRepository
                )
            } else {
                let accountStreamSources = walletsRepository
                    .getWallets()
                    .reversed()
                    .map { wallet in
                        AccountStreamSource(
                            account: wallet.pubkey ?? "",
                            symbol: wallet.token.symbol,
                            transactionRepository: transactionRepository
                        )
                    }

                source = MultipleStreamSource(sources: accountStreamSources)
            }
        }

        override func clear() {
            // Build source
            buildSource()

            super.clear()
        }

        override func reload() {
            super.reload()
            Task {
                await sellDataService.update()
            }
        }

        override func next() -> Observable<[HistoryItem]> {
            AsyncThrowingStream<[HistoryStreamSource.Result], Error> { stream in
                Task {
                    defer { stream.finish(throwing: nil) }

                    var results: [HistoryStreamSource.Result] = []
                    do {
                        while true {
                            let firstTrx = try await source.currentItem()
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
                            while let result = try await source.next(configuration: .init(timestampEnd: timeEndFilter))
                            {
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
            .flatMap { (signatures: [HistoryStreamSource.Result]) in
                let transactions = try await self.transactionRepository
                    .getTransactions(signatures: signatures.map(\.signatureInfo.signature))
                var parsedTransactions: [ParsedTransaction] = []

                for trxInfo in transactions {
                    guard let trxInfo = trxInfo else { continue }
                    guard let (signature, account, symbol) = signatures
                        .first(where: { (signatureInfo: SignatureInfo, _, _) in
                            signatureInfo.signature == trxInfo.transaction.signatures.first
                        }) else { continue }

                    parsedTransactions.append(
                        await self.transactionParserRepository.parse(
                            signatureInfo: signature,
                            transactionInfo: trxInfo,
                            account: account,
                            symbol: symbol
                        )
                    )
                }

                return parsedTransactions.map { .parsedTransaction($0) }
            }
            .do(onError: { [weak self] error in
                DispatchQueue.main.async { [weak self] in
                    self?.errorRelay.accept(true)
                    self?.notificationService.showInAppNotification(.error(error))
                }
            })
        }

        override func join(_ newItems: [HistoryItem]) -> [HistoryItem] {
            var filteredNewData: [HistoryItem] = []
            for trx in newItems {
                if data.contains(where: { $0.signature == trx.signature }) { continue }
                filteredNewData.append(trx)
            }
            return data + filteredNewData
        }

        override func map(newData: [HistoryItem]) -> [HistoryItem] {
            // Apply output transformation
            var data = newData
            for output in outputs { data = output.process(newData: data) }
            return super.map(newData: data)
        }

        func onTap(item: HistoryItem) {
            onTapPublisher.send(item)
        }
    }
}
