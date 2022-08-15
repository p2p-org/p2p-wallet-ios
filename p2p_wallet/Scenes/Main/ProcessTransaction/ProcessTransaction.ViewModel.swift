//
//  PT.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/12/2021.
//

import AnalyticsManager
import Combine
import Foundation
import Resolver
import SolanaSwift

protocol ProcessTransactionViewModelType {
    var navigationPublisher: AnyPublisher<ProcessTransaction.NavigatableScene?, Never> { get }
    var pendingTransactionPublisher: AnyPublisher<PendingTransaction, Never> { get }
    var observingTransactionIndexPublisher: AnyPublisher<Int?, Never> { get }

    var isSwapping: Bool { get }
    var transactionID: String? { get }

    func getMainDescription() -> String

    func sendAndObserveTransaction()
    func handleErrorRetryOrMakeAnotherTransaction()
    func navigate(to scene: ProcessTransaction.NavigatableScene)
}

extension ProcessTransaction {
    @MainActor
    class ViewModel: ObservableObject {
        // MARK: - Dependencies

        @Injected private var analyticsManager: AnalyticsManager
        @Injected private var transactionHandler: TransactionHandlerType

        // MARK: - Properties

        private var subscriptions = [AnyCancellable]()
        private let rawTransaction: RawTransactionType

        // MARK: - Subjects

        @Published private var pendingTransaction: PendingTransaction
        @Published private var observingTransactionIndex: Int?
        @Published private var navigatableScene: NavigatableScene?

        // MARK: - Initializer

        init(processingTransaction: RawTransactionType) {
            rawTransaction = processingTransaction
            pendingTransaction = .init(transactionId: nil, sentAt: Date(),
                                       rawTransaction: processingTransaction, status: .sending)
        }

        deinit {
            print("\(String(describing: self)) deinited")
        }
    }
}

extension ProcessTransaction.ViewModel: ProcessTransactionViewModelType {
    var navigationPublisher: AnyPublisher<ProcessTransaction.NavigatableScene?, Never> {
        $navigatableScene.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    var pendingTransactionPublisher: AnyPublisher<PendingTransaction, Never> {
        $pendingTransaction.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    var isSwapping: Bool {
        rawTransaction.isSwap
    }

    var transactionID: String? {
        pendingTransaction.transactionId
    }

    func getMainDescription() -> String {
        rawTransaction.mainDescription
    }

    var observingTransactionIndexPublisher: AnyPublisher<Int?, Never> {
        $observingTransactionIndex.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    // MARK: - Actions

    func sendAndObserveTransaction() {
        // send transaction and get observation index
        let index = transactionHandler.sendTransaction(rawTransaction)
        observingTransactionIndex = index

        // send and catch error
        let unknownErrorInfo = PendingTransaction(
            transactionId: nil,
            sentAt: Date(),
            rawTransaction: rawTransaction,
            status: .error(SolanaError.unknown.readableDescription)
        )

        // observe transaction based on transaction index
        transactionHandler.observeTransaction(transactionIndex: index)
            .map { $0 ?? unknownErrorInfo }
            .replaceError(with: unknownErrorInfo)
            .assign(to: \.pendingTransaction, on: self)
            .store(in: &subscriptions)
    }

    func handleErrorRetryOrMakeAnotherTransaction() {
        if pendingTransaction.status.error == nil {
            // log
            let status = pendingTransaction.status.rawValue
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
            if let error = pendingTransaction.status.error {
                switch rawTransaction {
                case is ProcessTransaction.SendTransaction:
                    analyticsManager.log(event: .sendTryAgainClick(error: error))
                case is ProcessTransaction.SwapTransaction:
                    analyticsManager.log(event: .swapTryAgainClick(error: error))
                default:
                    break
                }

                if error == L10n.swapInstructionExceedsDesiredSlippageLimit {
                    navigate(to: .specificErrorHandler(SolanaError.other(error)))
                    return
                }
            }

            sendAndObserveTransaction()
        }
    }

    func navigate(to scene: ProcessTransaction.NavigatableScene) {
        // log
        let status = pendingTransaction.status.rawValue
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
        navigatableScene = scene
    }
}
