//
//  PT.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/12/2021.
//

import Foundation
import Resolver
import RxCocoa
import RxSwift

protocol ProcessTransactionViewModelType {
    var navigationDriver: Driver<ProcessTransaction.NavigatableScene?> { get }
    var pendingTransactionDriver: Driver<PendingTransaction> { get }
    var observingTransactionIndexDriver: Driver<Int?> { get }

    var isSwapping: Bool { get }
    var transactionID: String? { get }

    func getMainDescription() -> String

    func sendAndObserveTransaction()
    func handleErrorRetryOrMakeAnotherTransaction()
    func navigate(to scene: ProcessTransaction.NavigatableScene)
}

extension ProcessTransaction {
    class ViewModel {
        // MARK: - Dependencies

        @Injected private var analyticsManager: AnalyticsManagerType
        @Injected private var transactionHandler: TransactionHandlerType

        // MARK: - Properties

        private let disposeBag = DisposeBag()
        private let rawTransaction: RawTransactionType

        // MARK: - Subjects

        private let pendingTransactionSubject: BehaviorRelay<PendingTransaction>
        private let observingTransactionIndexSubject = BehaviorRelay<Int?>(value: nil)

        // MARK: - Initializer

        init(processingTransaction: RawTransactionType) {
            rawTransaction = processingTransaction
            pendingTransactionSubject =
                BehaviorRelay<PendingTransaction>(value: .init(transactionId: nil, sentAt: Date(),
                                                               rawTransaction: processingTransaction, status: .sending))
        }

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }

        // MARK: - Subject

        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
    }
}

extension ProcessTransaction.ViewModel: ProcessTransactionViewModelType {
    var navigationDriver: Driver<ProcessTransaction.NavigatableScene?> {
        navigationSubject.asDriver()
    }

    var pendingTransactionDriver: Driver<PendingTransaction> {
        pendingTransactionSubject.asDriver()
    }

    var isSwapping: Bool {
        rawTransaction.isSwap
    }

    var transactionID: String? {
        pendingTransactionSubject.value.transactionId
    }

    func getMainDescription() -> String {
        rawTransaction.mainDescription
    }

    var observingTransactionIndexDriver: Driver<Int?> {
        observingTransactionIndexSubject.asDriver()
    }

    // MARK: - Actions

    func sendAndObserveTransaction() {
        // send transaction and get observation index
        let index = transactionHandler.sendTransaction(rawTransaction)
        observingTransactionIndexSubject.accept(index)

        // send and catch error
        let unknownErrorInfo = PendingTransaction(
            transactionId: nil,
            sentAt: Date(),
            rawTransaction: rawTransaction,
            status: .error(SolanaSDK.Error.unknown)
        )

        // observe transaction based on transaction index
        transactionHandler.observeTransaction(transactionIndex: index)
            .map { $0 ?? unknownErrorInfo }
            .catchAndReturn(unknownErrorInfo)
            .bind(to: pendingTransactionSubject)
            .disposed(by: disposeBag)
    }

    func handleErrorRetryOrMakeAnotherTransaction() {
        if pendingTransactionSubject.value.status.error == nil {
            // log
            let status = pendingTransactionSubject.value.status.rawValue
            switch rawTransaction {
            case is ProcessTransaction.SendTransaction:
                analyticsManager.log(event: .sendMakeAnotherTransactionClick(txStatus: status))
            case is ProcessTransaction.SwapTransaction:
                analyticsManager.log(event: .swapMakeAnotherTransactionClick(txStatus: status))
            default:
                break
            }

            navigate(to: .makeAnotherTransaction)
        } else {
            // log
            if let error = pendingTransactionSubject.value.status.error {
                switch rawTransaction {
                case is ProcessTransaction.SendTransaction:
                    analyticsManager.log(event: .sendTryAgainClick(error: error.readableDescription))
                case is ProcessTransaction.SwapTransaction:
                    analyticsManager.log(event: .swapTryAgainClick(error: error.readableDescription))
                default:
                    break
                }

                if error.readableDescription == L10n.swapInstructionExceedsDesiredSlippageLimit {
                    navigate(to: .specificErrorHandler(error))
                    return
                }
            }

            sendAndObserveTransaction()
        }
    }

    func navigate(to scene: ProcessTransaction.NavigatableScene) {
        // log
        let status = pendingTransactionSubject.value.status.rawValue
        switch scene {
        case .explorer:
            switch rawTransaction {
            case is ProcessTransaction.SendTransaction:
                analyticsManager.log(event: .sendExplorerClick(txStatus: status))
            case is ProcessTransaction.SwapTransaction:
                analyticsManager.log(event: .swapExplorerClick(txStatus: status))
            default:
                break
            }
        default:
            break
        }

        // navigate
        navigationSubject.accept(scene)
    }
}
