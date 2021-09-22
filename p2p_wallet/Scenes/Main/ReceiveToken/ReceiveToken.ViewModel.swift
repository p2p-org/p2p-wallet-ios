//
//  ReceiveToken.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/06/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol ReceiveTokenViewModelType {
    // MARK: - Drivers
    var navigationSceneDriver: Driver<ReceiveToken.NavigatableScene?> {get}
    var tokenTypeDriver: Driver<ReceiveToken.TokenType> {get}
    var updateLayoutDriver: Driver<Void> {get}
    var receiveSolanaViewModel: ReceiveTokenSolanaViewModelType {get}
    var receiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType {get}
    
    // MARK: - Actions
    func switchToken(_ tokenType: ReceiveToken.TokenType)
    func copyToClipboard(address: String, logEvent: AnalyticsEvent)
}

extension ReceiveToken {
    class ViewModel {
        // MARK: - Dependencies
        private let analyticsManager: AnalyticsManagerType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        let receiveSolanaViewModel: ReceiveTokenSolanaViewModelType
        let receiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType
        
        // MARK: - Subjects
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let tokenTypeSubject = BehaviorRelay<TokenType>(value: .solana)
        
        // MARK: - Initializers
        init(
            solanaPubkey: SolanaSDK.PublicKey,
            solanaTokenWallet: Wallet? = nil,
            analyticsManager: AnalyticsManagerType,
            tokensRepository: TokensRepository,
            renVMService: RenVMLockAndMintServiceType,
            isRenBTCWalletCreated: Bool,
            associatedTokenAccountHandler: AssociatedTokenAccountHandler
        ) {
            self.receiveSolanaViewModel = ReceiveToken.ReceiveSolanaViewModel(
                solanaPubkey: solanaPubkey.base58EncodedString,
                solanaTokenWallet: solanaTokenWallet,
                analyticsManager: analyticsManager,
                tokensRepository: tokensRepository,
                navigationSubject: navigationSubject
            )
            
            self.receiveBitcoinViewModel = ReceiveToken.ReceiveBitcoinViewModel(
                renVMService: renVMService,
                analyticsManager: analyticsManager,
                navigationSubject: navigationSubject,
                isRenBTCWalletCreated: isRenBTCWalletCreated,
                associatedTokenAccountHandler: associatedTokenAccountHandler
            )
            
            self.analyticsManager = analyticsManager
        }
    }
}

extension ReceiveToken.ViewModel: ReceiveTokenViewModelType {
    var navigationSceneDriver: Driver<ReceiveToken.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    var tokenTypeDriver: Driver<ReceiveToken.TokenType> {
        tokenTypeSubject.asDriver()
    }
    
    var updateLayoutDriver: Driver<Void> {
        Driver.combineLatest(
            tokenTypeDriver,
            receiveSolanaViewModel.isShowingDetailDriver,
            receiveBitcoinViewModel.isReceivingRenBTCDriver,
            receiveBitcoinViewModel.renBTCWalletCreatingDriver,
            receiveBitcoinViewModel.conditionAcceptedDriver,
            receiveBitcoinViewModel.addressDriver
        )
            .map {_ in ()}.asDriver()
    }
    
    func switchToken(_ tokenType: ReceiveToken.TokenType) {
        tokenTypeSubject.accept(tokenType)
    }
    
    func copyToClipboard(address: String, logEvent: AnalyticsEvent) {
        UIApplication.shared.copyToClipboard(address, alert: false)
        analyticsManager.log(event: logEvent)
    }
}
