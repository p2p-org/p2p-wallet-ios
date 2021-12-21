//
//  ReceiveToken.ReceiveBitcoinViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/09/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol ReceiveTokenBitcoinViewModelType {
    var isReceivingRenBTCDriver: Driver<Bool> {get}
    var isLoadingDriver: Driver<Bool> {get}
    var errorDriver: Driver<String?> {get}
    var renBTCWalletCreatingDriver: Driver<Loadable<String>> {get}
    var conditionAcceptedDriver: Driver<Bool> {get}
    var addressDriver: Driver<String?> {get}
    var timerSignal: Signal<Void> {get}
    var minimumTransactionAmountDriver: Driver<Loadable<Double>> {get}
    var processingTxsDriver: Driver<[RenVM.LockAndMint.ProcessingTx]> {get}
    
    func reload()
    func reloadMinimumTransactionAmount()
    func getSessionEndDate() -> Date?
    func createRenBTCWallet()
    func acceptConditionAndLoadAddress()
    func toggleIsReceivingRenBTC(isReceivingRenBTC: Bool)
    func showBTCTypeOptions()
    func showReceivingStatuses()
    func copyToClipboard(address: String, logEvent: AnalyticsEvent)
    func share()
    func showBTCAddressInExplorer()
}

extension ReceiveToken {
    class ReceiveBitcoinViewModel {
        // MARK: - Constants
        private let disposeBag = DisposeBag()
        
        // MARK: - Dependencies
        private let renVMService: RenVMLockAndMintServiceType
        @Injected private var analyticsManager: AnalyticsManagerType
        private let navigationSubject: PublishRelay<NavigatableScene?>
        private let associatedTokenAccountHandler: AssociatedTokenAccountHandler
        
        // MARK: - Subjects
        private let isReceivingRenBTCSubject = BehaviorRelay<Bool>(value: true)
        private let createRenBTCSubject: LoadableRelay<String>
        private let timerSubject = PublishRelay<Void>()
        
        // MARK: - Initializers
        init(
            renVMService: RenVMLockAndMintServiceType,
            navigationSubject: PublishRelay<NavigatableScene?>,
            isRenBTCWalletCreated: Bool,
            associatedTokenAccountHandler: AssociatedTokenAccountHandler
        ) {
            self.renVMService = renVMService
            self.navigationSubject = navigationSubject
            self.associatedTokenAccountHandler = associatedTokenAccountHandler
            
            self.createRenBTCSubject = .init(
                request: associatedTokenAccountHandler
                    .createAssociatedTokenAccount(tokenMint: .renBTCMint, isSimulation: false)
                    .catch {error in
                        if error.isAlreadyInUseSolanaError {
                            return .just("")
                        }
                        throw error
                    }
            )
            
            if isRenBTCWalletCreated {
                createRenBTCSubject.accept(nil, state: .loaded)
            }
            
            bind()
        }
        
        func reload() {
            renVMService.reload()
        }
        
        func createRenBTCWallet() {
            createRenBTCSubject.reload()
        }
        
        func acceptConditionAndLoadAddress() {
            renVMService.acceptConditionAndLoadAddress()
        }
        
        private func bind() {
            Timer.observable(seconds: 1)
                .bind(to: timerSubject)
                .disposed(by: disposeBag)
            
            timerSubject
                .subscribe(onNext: { [weak self] in
                    guard let endAt = self?.getSessionEndDate() else {return}
                    if Date() >= endAt {
                        self?.renVMService.expireCurrentSession()
                    }
                })
                .disposed(by: disposeBag)
        }
        
        func toggleIsReceivingRenBTC(isReceivingRenBTC: Bool) {
            isReceivingRenBTCSubject.accept(isReceivingRenBTC)
        }
        
        func showBTCTypeOptions() {
            navigationSubject.accept(.chooseBTCOption(selectedOption: isReceivingRenBTCSubject.value ? .renBTC: .splBTC))
        }
    }
}

extension ReceiveToken.ReceiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType {
    var isReceivingRenBTCDriver: Driver<Bool> {
        isReceivingRenBTCSubject.asDriver()
    }
    
    var isLoadingDriver: Driver<Bool> {
        renVMService.isLoadingDriver
    }
    
    var errorDriver: Driver<String?> {
        renVMService.errorDriver
    }
    
    var renBTCWalletCreatingDriver: Driver<Loadable<String>> {
        createRenBTCSubject.asDriver()
    }
    
    var conditionAcceptedDriver: Driver<Bool> {
        renVMService.conditionAcceptedDriver
    }
    
    var addressDriver: Driver<String?> {
        renVMService.addressDriver
    }
    
    var timerSignal: Signal<Void> {
        timerSubject.asSignal()
    }
    
    var minimumTransactionAmountDriver: Driver<Loadable<Double>> {
        renVMService.minimumTransactionAmountDriver
    }
    
    var processingTxsDriver: Driver<[RenVM.LockAndMint.ProcessingTx]> {
        renVMService.processingTxsDriver
    }
    
    func getSessionEndDate() -> Date? {
        renVMService.getSessionEndDate()
    }
    
    func copyToClipboard(address: String, logEvent: AnalyticsEvent) {
        UIApplication.shared.copyToClipboard(address, alert: false)
        analyticsManager.log(event: logEvent)
    }
    
    func share() {
        guard let address = renVMService.getCurrentAddress() else {return}
        analyticsManager.log(event: .receiveAddressShare)
        navigationSubject.accept(.share(address: address))
    }
    
    func showBTCAddressInExplorer() {
        guard let address = renVMService.getCurrentAddress() else {return}
        analyticsManager.log(event: .receiveViewExplorerOpen)
        navigationSubject.accept(.showBTCExplorer(address: address))
    }
    
    func reloadMinimumTransactionAmount() {
        renVMService.reloadMinimumTransactionAmount()
    }
    
    func showReceivingStatuses() {
        navigationSubject.accept(.showRenBTCReceivingStatus)
    }
}
