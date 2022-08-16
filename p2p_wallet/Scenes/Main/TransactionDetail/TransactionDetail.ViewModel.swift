//
//  TransactionDetail.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/03/2022.
//

import Combine
import Foundation
import NameService
import Resolver
import SolanaSwift
import TransactionParser

protocol TransactionDetailViewModelType: AnyObject {
    var navigatableScenePublisher: AnyPublisher<TransactionDetail.NavigatableScene?, Never> { get }
    var parsedTransactionPublisher: AnyPublisher<ParsedTransaction?, Never> { get }
    var navigationTitle: AnyPublisher<String, Never> { get }
    var senderNamePublisher: AnyPublisher<String?, Never> { get }
    var receiverNamePublisher: AnyPublisher<String?, Never> { get }
    var isSummaryAvailablePublisher: AnyPublisher<Bool, Never> { get }
    var isFromToSectionAvailablePublisher: AnyPublisher<Bool, Never> { get }

    func getTransactionId() -> String?
    func getPayingFeeWallet() -> Wallet?
    func getCreatedAccountSymbol() -> String?
    func getAmountInCurrentFiat(amountInToken: Double?, symbol: String?) -> Double?

    func navigate(to scene: TransactionDetail.NavigatableScene)

    func copyTransactionIdToClipboard()
    func copySourceAddressToClipboard()
    func copyDestinationAddressToClipboard()
}

extension TransactionDetail {
    class ViewModel: BaseViewModel {
        // MARK: - Dependencies

        @Injected private var transactionHandler: TransactionHandlerType
        @Injected private var pricesService: PricesServiceType
        @Injected private var walletsRepository: WalletsRepository
        @Injected private var nameService: NameService
        @Injected private var clipboardManager: ClipboardManagerType
        @Injected private var notificationService: NotificationService

        // MARK: - Properties

        private let observingTransactionIndex: TransactionHandlerType.TransactionIndex?
        private var payingFeeWallet: Wallet?

        // MARK: - Subject

        @Published private var navigatableScene: NavigatableScene?
        @Published private var parsedTransationSubject: ParsedTransaction?
        @Published private var senderNameSubject: String?
        @Published private var receiverNameSubject: String?

        // MARK: - Initializers

        init(parsedTransaction: ParsedTransaction) {
            observingTransactionIndex = nil
            super.init()
            parsedTransationSubject = parsedTransaction

            mapNames(parsedTransaction: parsedTransaction)
        }

        init(observingTransactionIndex: TransactionHandlerType.TransactionIndex) {
            self.observingTransactionIndex = observingTransactionIndex
            super.init()
            bind()
        }

        func bind() {
            transactionHandler
                .observeTransaction(transactionIndex: observingTransactionIndex!)
                .receive(on: RunLoop.main)
                .handleEvents(receiveOutput: { [weak self] pendingTransaction in
                    self?.payingFeeWallet = pendingTransaction?.rawTransaction.payingWallet
                })
                .map { [weak self] pendingTransaction -> ParsedTransaction? in
                    guard let self = self else { return nil }
                    return pendingTransaction?.parse(
                        pricesService: self.pricesService,
                        authority: self.walletsRepository.nativeWallet?.pubkey
                    )
                }
                .replaceError(with: nil)
                .handleEvents(receiveOutput: { [weak self] parsedTransaction in
                    self?.mapNames(parsedTransaction: parsedTransaction)
                })
                .assign(to: \.parsedTransationSubject, on: self)
                .store(in: &subscriptions)
        }

        func mapNames(parsedTransaction: ParsedTransaction?) {
            let fromAddress: String?
            let toAddress: String?
            switch parsedTransaction?.info {
            case let transaction as TransferInfo:
                fromAddress = transaction.authority ?? transaction.source?.pubkey
                toAddress = transaction.destinationAuthority ?? transaction.destination?.pubkey
            default:
                return
            }

            guard fromAddress != nil || toAddress != nil else {
                return
            }

            Task {
                async let fromName: String? = fromAddress != nil ? nameService.getName(fromAddress!) : nil
                async let toName: String? = toAddress != nil ? nameService.getName(toAddress!) : nil

                await senderNameSubject = try? fromName?.withNameServiceDomain()
                await receiverNameSubject = try? toName?.withNameServiceDomain()
            }
        }
    }
}

extension TransactionDetail.ViewModel: TransactionDetailViewModelType {
    var navigatableScenePublisher: AnyPublisher<TransactionDetail.NavigatableScene?, Never> {
        $navigatableScene.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    var parsedTransactionPublisher: AnyPublisher<ParsedTransaction?, Never> {
        $parsedTransationSubject.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    var navigationTitle: AnyPublisher<String, Never> {
        parsedTransactionPublisher
            .map { parsedTransaction -> String in
                var text = L10n.transaction

                switch parsedTransaction?.info {
                case let createAccountTransaction as CreateAccountInfo:
                    if let createdToken = createAccountTransaction.newWallet?.token.symbol {
                        text = L10n.created(createdToken)
                    }
                case let closedAccountTransaction as CloseAccountInfo:
                    if let closedToken = closedAccountTransaction.closedWallet?.token.symbol {
                        text = L10n.closed(closedToken)
                    }

                case let transferTransaction as TransferInfo:
                    if let symbol = transferTransaction.source?.token.symbol,
                       let receiverPubkey = transferTransaction.destination?.pubkey
                    {
                        text = symbol + " → " + receiverPubkey
                            .truncatingMiddle(numOfSymbolsRevealed: 4, numOfSymbolsRevealedInSuffix: 4)
                    }

                case let swapTransaction as SwapInfo:
                    if let sourceSymbol = swapTransaction.source?.token.symbol ?? swapTransaction.source?
                        .mintAddress.truncatingMiddle(
                            numOfSymbolsRevealed: 4,
                            numOfSymbolsRevealedInSuffix: 4
                        ),
                        let destinationSymbol = swapTransaction.destination?.token.symbol ?? swapTransaction
                            .destination?.mintAddress.truncatingMiddle(
                                numOfSymbolsRevealed: 4,
                                numOfSymbolsRevealedInSuffix: 4
                            )
                    {
                        text = sourceSymbol + " → " + destinationSymbol
                    }
                default:
                    break
                }
                return text
            }
            .eraseToAnyPublisher()
    }

    var senderNamePublisher: AnyPublisher<String?, Never> {
        $senderNameSubject.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    var receiverNamePublisher: AnyPublisher<String?, Never> {
        $receiverNameSubject.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    var isSummaryAvailablePublisher: AnyPublisher<Bool, Never> {
        $parsedTransationSubject
            .map { parsedTransaction in
                switch parsedTransaction?.info {
                case _ as CreateAccountInfo:
                    return false
                case _ as CloseAccountInfo:
                    return false

                case _ as TransferInfo:
                    return true

                case _ as SwapInfo:
                    return true
                default:
                    return false
                }
            }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    var isFromToSectionAvailablePublisher: AnyPublisher<Bool, Never> {
        isSummaryAvailablePublisher
    }

    func getTransactionId() -> String? {
        parsedTransationSubject?.signature
    }

    func getPayingFeeWallet() -> Wallet? {
        payingFeeWallet
    }

    func getCreatedAccountSymbol() -> String? {
        let createdWallet: String?
        switch parsedTransationSubject?.info {
        case let transaction as TransferInfo:
            createdWallet = transaction.destination?.token.symbol
        case let transaction as SwapInfo:
            createdWallet = transaction.destination?.token.symbol
        default:
            return nil
        }
        return createdWallet
    }

    func getAmountInCurrentFiat(amountInToken: Double?, symbol: String?) -> Double? {
        guard let amountInToken = amountInToken,
              let symbol = symbol,
              let price = pricesService.currentPrice(for: symbol)?.value
        else {
            return nil
        }

        return amountInToken * price
    }

    // MARK: - Actions

    func navigate(to scene: TransactionDetail.NavigatableScene) {
        navigatableScene = scene
    }

    func copyTransactionIdToClipboard() {
        guard let transactionId = parsedTransationSubject?.signature else { return }
        clipboardManager.copyToClipboard(transactionId)
        notificationService.showInAppNotification(.done(L10n.copiedToClipboard))
    }

    func copySourceAddressToClipboard() {
        let sourceAddress: String?
        switch parsedTransationSubject?.info {
        case let transaction as TransferInfo:
            sourceAddress = transaction.source?.pubkey
        case let transaction as SwapInfo:
            sourceAddress = transaction.source?.pubkey
        default:
            return
        }
        guard let sourceAddress = sourceAddress else {
            return
        }
        clipboardManager.copyToClipboard(sourceAddress)
        notificationService.showInAppNotification(.done(L10n.copiedToClipboard))
    }

    func copyDestinationAddressToClipboard() {
        let destinationAddress: String?
        switch parsedTransationSubject?.info {
        case let transaction as TransferInfo:
            destinationAddress = transaction.destination?.pubkey
        case let transaction as SwapInfo:
            destinationAddress = transaction.destination?.pubkey
        default:
            return
        }
        guard let destinationAddress = destinationAddress else {
            return
        }
        clipboardManager.copyToClipboard(destinationAddress)
        notificationService.showInAppNotification(.done(L10n.copiedToClipboard))
    }
}
