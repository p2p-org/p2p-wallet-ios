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
    
    // MARK: - Actions
    func switchToken(_ tokenType: ReceiveToken.TokenType)
    func copyToClipboard(address: String, logEvent: AnalyticsEvent)
}

protocol ReceiveTokenSolanaViewModelType {
    var isShowingDetailDriver: Driver<Bool> {get}
    var pubkey: String {get}
    var tokenWallet: Wallet? {get}
    var tokensCountDriver: Driver<Int> {get}
    
    func showSOLAddressInExplorer()
    func showTokenMintAddressInExplorer()
    func showTokenPubkeyAddressInExplorer()
    func share()
    func showHelp()
    func toggleIsShowingDetail()
    func copyToClipboard(address: String, logEvent: AnalyticsEvent)
}

extension ReceiveToken {
    class NewViewModel {
        // MARK: - Dependencies
        private let analyticsManager: AnalyticsManagerType
        private let tokensRepository: TokensRepository
        
        // MARK: - Properties
        let pubkey: String
        let tokenWallet: Wallet?
        private let disposeBag = DisposeBag()
        
        // MARK: - Subjects
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let tokenTypeSubject = BehaviorRelay<TokenType>(value: .solana)
        
        // Solana
        private let solanaIsShowingDetailSubject = BehaviorRelay<Bool>(value: false)
        private let solanaTokenListSubject = BehaviorRelay<[SolanaSDK.Token]>(value: [])
        
        // MARK: - Initializers
        init(
            solanaPubkey: String,
            solanaTokenWallet: Wallet? = nil,
            analyticsManager: AnalyticsManagerType,
            tokensRepository: TokensRepository
        ) {
            self.pubkey = solanaPubkey
            self.analyticsManager = analyticsManager
            self.tokensRepository = tokensRepository
            var tokenWallet = solanaTokenWallet
            if solanaTokenWallet?.pubkey == solanaPubkey {
                tokenWallet = nil
            }
            self.tokenWallet = tokenWallet
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
        isShowingDetailDriver.map {_ in ()}.asDriver()
    }
    
    func switchToken(_ tokenType: ReceiveToken.TokenType) {
        tokenTypeSubject.accept(tokenType)
    }
    
    func copyToClipboard(address: String, logEvent: AnalyticsEvent) {
        UIApplication.shared.copyToClipboard(address, alert: false)
        analyticsManager.log(event: logEvent)
    }
}

extension ReceiveToken.NewViewModel: ReceiveTokenSolanaViewModelType {
    var isShowingDetailDriver: Driver<Bool> {
        solanaIsShowingDetailSubject.asDriver()
    }
    
    var tokensCountDriver: Driver<Int> {
        tokensRepository.getTokensList()
            .map {$0.count}
            .asDriver(onErrorJustReturn: 554)
    }
    
    func showSOLAddressInExplorer() {
        analyticsManager.log(event: .receiveViewExplorerOpen)
        navigationSubject.accept(.showInExplorer(address: pubkey))
    }
    
    func showTokenMintAddressInExplorer() {
        guard let mintAddress = tokenWallet?.token.address else {return}
        analyticsManager.log(event: .receiveViewExplorerOpen)
        navigationSubject.accept(.showInExplorer(address: mintAddress))
    }
    
    func showTokenPubkeyAddressInExplorer() {
        guard let pubkey = tokenWallet?.pubkey else {return}
        analyticsManager.log(event: .receiveViewExplorerOpen)
        navigationSubject.accept(.showInExplorer(address: pubkey))
    }
    
    func share() {
        analyticsManager.log(event: .receiveAddressShare)
        navigationSubject.accept(.share(address: pubkey))
    }
    
    func showHelp() {
        navigationSubject.accept(.help)
    }
    
    func toggleIsShowingDetail() {
        solanaIsShowingDetailSubject.accept(!solanaIsShowingDetailSubject.value)
    }
}
