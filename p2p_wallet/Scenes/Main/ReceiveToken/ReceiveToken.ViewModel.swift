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
    
    // MARK: - Actions
    func switchToken(_ tokenType: ReceiveToken.TokenType)
    func copyToClipboard(address: String, logEvent: AnalyticsEvent)
}

extension ReceiveToken {
    class NewViewModel {
        // MARK: - Dependencies
        private let analyticsManager: AnalyticsManagerType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        let receiveSolanaViewModel: ReceiveTokenSolanaViewModelType
        
        // MARK: - Subjects
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let tokenTypeSubject = BehaviorRelay<TokenType>(value: .solana)
        
        // MARK: - Initializers
        init(
            solanaPubkey: String,
            solanaTokenWallet: Wallet? = nil,
            analyticsManager: AnalyticsManagerType,
            tokensRepository: TokensRepository
        ) {
            self.receiveSolanaViewModel = ReceiveToken.ReceiveSolanaViewModel(
                solanaPubkey: solanaPubkey,
                solanaTokenWallet: solanaTokenWallet,
                analyticsManager: analyticsManager,
                tokensRepository: tokensRepository,
                navigationSubject: navigationSubject
            )
            
            self.analyticsManager = analyticsManager
        }
    }
}

extension ReceiveToken.NewViewModel: ReceiveTokenViewModelType {
    var navigationSceneDriver: Driver<ReceiveToken.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    var tokenTypeDriver: Driver<ReceiveToken.TokenType> {
        tokenTypeSubject.asDriver()
    }
    
    var updateLayoutDriver: Driver<Void> {
        receiveSolanaViewModel.isShowingDetailDriver.map {_ in ()}.asDriver()
    }
    
    func switchToken(_ tokenType: ReceiveToken.TokenType) {
        tokenTypeSubject.accept(tokenType)
    }
    
    func copyToClipboard(address: String, logEvent: AnalyticsEvent) {
        UIApplication.shared.copyToClipboard(address, alert: false)
        analyticsManager.log(event: logEvent)
    }
}
