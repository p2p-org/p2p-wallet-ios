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
    
    // Solana
    var solanaIsShowingDetailDriver: Driver<Bool> {get}
    var solanaPubkey: String {get}
    var solanaTokenWallet: Wallet? {get}
    var solanaTokensCountDriver: Driver<Int> {get}
    
    // Btc
    
    // MARK: - Actions
    func switchToken(_ tokenType: ReceiveToken.TokenType)
    func copyToClipboard(address: String, logEvent: AnalyticsEvent)
    
    // Solana
    func solanaShowSOLAddressInExplorer()
    func solanaShowTokenMintAddressInExplorer()
    func solanaShowTokenPubkeyAddressInExplorer()
    func solanaShare()
    func solanaShowHelp()
    func solanaToggleIsShowingDetail()
    
}

extension ReceiveToken {
    class NewViewModel {
        // MARK: - Dependencies
        private let analyticsManager: AnalyticsManagerType
        private let tokensRepository: TokensRepository
        
        // MARK: - Properties
        let solanaPubkey: String
        let solanaTokenWallet: Wallet?
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
            self.solanaPubkey = solanaPubkey
            self.analyticsManager = analyticsManager
            self.tokensRepository = tokensRepository
            var tokenWallet = solanaTokenWallet
            if solanaTokenWallet?.pubkey == solanaPubkey {
                tokenWallet = nil
            }
            self.solanaTokenWallet = tokenWallet
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
    
    var solanaIsShowingDetailDriver: Driver<Bool> {
        solanaIsShowingDetailSubject.asDriver()
    }
    
    var solanaTokensCountDriver: Driver<Int> {
        tokensRepository.getTokensList()
            .map {$0.count}
            .asDriver(onErrorJustReturn: 554)
    }
    
    func switchToken(_ tokenType: ReceiveToken.TokenType) {
        tokenTypeSubject.accept(tokenType)
    }
    
    func copyToClipboard(address: String, logEvent: AnalyticsEvent) {
        UIApplication.shared.copyToClipboard(address, alert: false)
        analyticsManager.log(event: logEvent)
    }
    
    func solanaShowSOLAddressInExplorer() {
        analyticsManager.log(event: .receiveViewExplorerOpen)
        navigationSubject.accept(.showInExplorer(address: solanaPubkey))
    }
    
    func solanaShowTokenMintAddressInExplorer() {
        guard let mintAddress = solanaTokenWallet?.token.address else {return}
        analyticsManager.log(event: .receiveViewExplorerOpen)
        navigationSubject.accept(.showInExplorer(address: mintAddress))
    }
    
    func solanaShowTokenPubkeyAddressInExplorer() {
        guard let pubkey = solanaTokenWallet?.pubkey else {return}
        analyticsManager.log(event: .receiveViewExplorerOpen)
        navigationSubject.accept(.showInExplorer(address: pubkey))
    }
    
    func solanaShare() {
        analyticsManager.log(event: .receiveAddressShare)
        navigationSubject.accept(.share(address: solanaPubkey))
    }
    
    func solanaShowHelp() {
        navigationSubject.accept(.help)
    }
    
    func solanaToggleIsShowingDetail() {
        solanaIsShowingDetailSubject.accept(!solanaIsShowingDetailSubject.value)
    }
}
