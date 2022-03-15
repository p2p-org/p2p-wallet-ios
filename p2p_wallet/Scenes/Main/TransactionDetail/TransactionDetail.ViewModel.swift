//
//  TransactionDetail.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/03/2022.
//

import Foundation
import RxSwift
import RxCocoa
import SolanaSwift
import Resolver

protocol TransactionDetailViewModelType: AnyObject {
    var navigationDriver: Driver<TransactionDetail.NavigatableScene?> {get}
    var parsedTransactionDriver: Driver<SolanaSDK.ParsedTransaction?> {get}
    var senderNameDriver: Driver<String?> {get}
    var receiverNameDriver: Driver<String?> {get}
    var isSummaryAvailableDriver: Driver<Bool> {get}
    var isFromToSectionAvailableDriver: Driver<Bool> {get}
    
    func getTransactionId() -> String?
    func getAmountInCurrentFiat(amountInToken: Double?, symbol: String?) -> Double?
    
    func navigate(to scene: TransactionDetail.NavigatableScene)
    
    func copyTransactionIdToClipboard()
    func copySourceAddressToClipboard()
    func copySourceNameToClipboard()
    func copyDestinationAddressToClipboard()
    func copyDestinationNameToClipboard()
}

extension TransactionDetail {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var transactionHandler: TransactionHandlerType
        @Injected private var pricesService: PricesServiceType
        @Injected private var walletsRepository: WalletsRepository
        @Injected private var nameService: NameServiceType
        @Injected private var clipboardManager: ClipboardManagerType
        @Injected private var notificationService: NotificationsServiceType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        private let observingTransactionIndex: TransactionHandlerType.TransactionIndex?
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let parsedTransationSubject: BehaviorRelay<SolanaSDK.ParsedTransaction?>
        private let senderNameSubject = BehaviorRelay<String?>(value: nil)
        private let receiverNameSubject = BehaviorRelay<String?>(value: nil)
        
        // MARK: - Initializers
        init(parsedTransaction: SolanaSDK.ParsedTransaction) {
            observingTransactionIndex = nil
            parsedTransationSubject = .init(value: parsedTransaction)
            
            mapNames(parsedTransaction: parsedTransaction)
        }
        
        init(observingTransactionIndex: TransactionHandlerType.TransactionIndex) {
            self.observingTransactionIndex = observingTransactionIndex
            self.parsedTransationSubject = .init(value: nil)
            
            bind()
        }
        
        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }
        
        func bind() {
            transactionHandler
                .observeTransaction(transactionIndex: observingTransactionIndex!)
                .map { [weak self] pendingTransaction -> SolanaSDK.ParsedTransaction? in
                    guard let self = self else {return nil}
                    return pendingTransaction?.parse(pricesService: self.pricesService, authority: self.walletsRepository.nativeWallet?.pubkey)
                }
                .catchAndReturn(nil)
                .observe(on: MainScheduler.instance)
                .do(onNext: { [weak self] parsedTransaction in
                    self?.mapNames(parsedTransaction: parsedTransaction)
                })
                .bind(to: parsedTransationSubject)
                .disposed(by: disposeBag)
        }
        
        func mapNames(parsedTransaction: SolanaSDK.ParsedTransaction?) {
            var fromAddress: String?
            var toAddress: String?
            switch parsedTransaction?.value {
            case let transaction as SolanaSDK.TransferTransaction:
                fromAddress = transaction.source?.pubkey
                toAddress = transaction.destination?.pubkey
            default:
                return
            }
            
            guard fromAddress != nil || toAddress != nil else {
                return
            }
            
            let fromNameRequest: Single<String?>
            if let fromAddress = fromAddress {
                fromNameRequest = nameService.getName(fromAddress)
            } else {
                fromNameRequest = .just(nil)
            }
            
            fromNameRequest
                .observe(on: MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] fromName in
                    self?.senderNameSubject.accept(fromName?.withNameServiceDomain())
                })
                .disposed(by: disposeBag)
            
            let toNameRequest: Single<String?>
            if let toAddress = toAddress {
                toNameRequest = nameService.getName(toAddress)
            } else {
                toNameRequest = .just(nil)
            }
            
            toNameRequest
                .observe(on: MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] toName in
                    self?.receiverNameSubject.accept(toName?.withNameServiceDomain())
                })
                .disposed(by: disposeBag)
        }
    }
}

extension TransactionDetail.ViewModel: TransactionDetailViewModelType {
    var navigationDriver: Driver<TransactionDetail.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    var parsedTransactionDriver: Driver<SolanaSDK.ParsedTransaction?> {
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
                switch parsedTransaction?.value {
                case _ as SolanaSDK.CreateAccountTransaction:
                    return false
                case _ as SolanaSDK.CloseAccountTransaction:
                    return false
                
                case _ as SolanaSDK.TransferTransaction:
                    return true
                    
                case _ as SolanaSDK.SwapTransaction:
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
        guard let transactionId = parsedTransationSubject.value?.signature else {return}
        clipboardManager.copyToClipboard(transactionId)
        notificationService.showInAppNotification(.done(L10n.copiedToClipboard))
    }
    
    func copySourceAddressToClipboard() {
        let sourceAddress: String?
        switch parsedTransationSubject.value?.value {
        case let transaction as SolanaSDK.TransferTransaction:
            sourceAddress = transaction.source?.pubkey
        case let transaction as SolanaSDK.SwapTransaction:
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
    
    func copySourceNameToClipboard() {
        guard let name = senderNameSubject.value else {return}
        clipboardManager.copyToClipboard(name)
        notificationService.showInAppNotification(.done(L10n.copiedToClipboard))
    }
    
    func copyDestinationAddressToClipboard() {
        let destinationAddress: String?
        switch parsedTransationSubject.value?.value {
        case let transaction as SolanaSDK.TransferTransaction:
            destinationAddress = transaction.destination?.pubkey
        case let transaction as SolanaSDK.SwapTransaction:
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
    
    func copyDestinationNameToClipboard() {
        guard let name = receiverNameSubject.value else {return}
        clipboardManager.copyToClipboard(name)
        notificationService.showInAppNotification(.done(L10n.copiedToClipboard))
    }
}
