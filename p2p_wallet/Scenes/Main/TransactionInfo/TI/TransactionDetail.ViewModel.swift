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

protocol TransactionDetailViewModelType {
    var navigationDriver: Driver<TransactionDetail.NavigatableScene?> {get}
    var parsedTransactionDriver: Driver<SolanaSDK.ParsedTransaction?> {get}
    var isSummaryAvailableDriver: Driver<Bool> {get}
    
    func getTransactionId() -> String?
    
    func navigate(to scene: TransactionDetail.NavigatableScene)
}

extension TransactionDetail {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var transactionHandler: TransactionHandlerType
        @Injected private var pricesService: PricesServiceType
        @Injected private var walletsRepository: WalletsRepository
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        private let observingTransactionIndex: TransactionHandlerType.TransactionIndex?
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let parsedTransationSubject: BehaviorRelay<SolanaSDK.ParsedTransaction?>
        
        // MARK: - Initializers
        init(parsedTransaction: SolanaSDK.ParsedTransaction) {
            observingTransactionIndex = nil
            parsedTransationSubject = .init(value: parsedTransaction)
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
                .bind(to: parsedTransationSubject)
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
    
    func getTransactionId() -> String? {
        parsedTransationSubject.value?.signature
    }
    
    // MARK: - Actions
    func navigate(to scene: TransactionDetail.NavigatableScene) {
        navigationSubject.accept(scene)
    }
}
