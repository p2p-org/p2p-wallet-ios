//
//  TransactionDetail.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/03/2022.
//

import Foundation
import Resolver
import RxCocoa
import RxSwift
import SolanaSwift
import TransactionParser

protocol TransactionDetailViewModelType: AnyObject {
    var navigationDriver: Driver<TransactionDetail.NavigatableScene?> { get }
    var parsedTransactionDriver: Driver<ParsedTransaction?> { get }
    var senderNameDriver: Driver<String?> { get }
    var receiverNameDriver: Driver<String?> { get }
    var isSummaryAvailableDriver: Driver<Bool> { get }
    var isFromToSectionAvailableDriver: Driver<Bool> { get }

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
    class ViewModel {
        // MARK: - Dependencies

        @Injected private var transactionHandler: TransactionHandlerType
        @Injected private var pricesService: PricesServiceType
        @Injected private var walletsRepository: WalletsRepository
        @Injected private var nameService: NameServiceType
        @Injected private var clipboardManager: ClipboardManagerType
        @Injected private var notificationService: NotificationService

        // MARK: - Properties

        private let disposeBag = DisposeBag()
        private let observingTransactionIndex: TransactionHandlerType.TransactionIndex?
        private var payingFeeWallet: Wallet?

        // MARK: - Subject

        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let parsedTransationSubject: BehaviorRelay<ParsedTransaction?>
        private let senderNameSubject = BehaviorRelay<String?>(value: nil)
        private let receiverNameSubject = BehaviorRelay<String?>(value: nil)

        // MARK: - Initializers

        init(parsedTransaction: ParsedTransaction) {
            observingTransactionIndex = nil
            parsedTransationSubject = .init(value: parsedTransaction)

            mapNames(parsedTransaction: parsedTransaction)
        }

        init(observingTransactionIndex: TransactionHandlerType.TransactionIndex) {
            self.observingTransactionIndex = observingTransactionIndex
            parsedTransationSubject = .init(value: nil)

            bind()
        }

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }

        func bind() {
            transactionHandler
                .observeTransaction(transactionIndex: observingTransactionIndex!)
                .observe(on: MainScheduler.instance)
                .do(onNext: { [weak self] pendingTransaction in
                    guard let self = self else { return }
                    self.payingFeeWallet = pendingTransaction?.rawTransaction.payingWallet
                })
                .map { [weak self] pendingTransaction -> ParsedTransaction? in
                    guard let self = self else { return nil }
                    return pendingTransaction?.parse(
                        pricesService: self.pricesService,
                        authority: self.walletsRepository.nativeWallet?.pubkey
                    )
                }
                .catchAndReturn(nil)
                .do(onNext: { [weak self] parsedTransaction in
                    self?.mapNames(parsedTransaction: parsedTransaction)
                })
                .bind(to: parsedTransationSubject)
                .disposed(by: disposeBag)
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

                await senderNameSubject.accept(try? fromName?.withNameServiceDomain())
                await receiverNameSubject.accept(try? toName?.withNameServiceDomain())
            }
        }
    }
}

extension TransactionDetail.ViewModel: TransactionDetailViewModelType {
    var navigationDriver: Driver<TransactionDetail.NavigatableScene?> {
        navigationSubject.asDriver()
    }

    var parsedTransactionDriver: Driver<ParsedTransaction?> {
        parsedTransationSubject.asDriver()
    }

    var senderNameDriver: Driver<String?> {
        senderNameSubject.asDriver()
    }

    var receiverNameDriver: Driver<String?> {
        receiverNameSubject.asDriver()
    }

    var isSummaryAvailableDriver: Driver<Bool> {
        parsedTransationSubject
            .asDriver()
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
    }

    var isFromToSectionAvailableDriver: Driver<Bool> {
        isSummaryAvailableDriver
    }

    func getTransactionId() -> String? {
        parsedTransationSubject.value?.signature
    }

    func getPayingFeeWallet() -> Wallet? {
        payingFeeWallet
    }

    func getCreatedAccountSymbol() -> String? {
        let createdWallet: String?
        switch parsedTransationSubject.value?.info {
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
        navigationSubject.accept(scene)
    }

    func copyTransactionIdToClipboard() {
        guard let transactionId = parsedTransationSubject.value?.signature else { return }
        clipboardManager.copyToClipboard(transactionId)
        notificationService.showInAppNotification(.done(L10n.copiedToClipboard))
    }

    func copySourceAddressToClipboard() {
        let sourceAddress: String?
        switch parsedTransationSubject.value?.info {
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
        switch parsedTransationSubject.value?.info {
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
