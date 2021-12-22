//
//  ReceiveToken.SceneModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/06/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol ReceiveSceneModel: BESceneModel {
    var tokenTypeDriver: Driver<ReceiveToken.TokenType> { get }
    var updateLayoutDriver: Driver<Void> { get }
    var receiveSolanaViewModel: ReceiveTokenSolanaViewModelType { get }
    var receiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType { get }
    var shouldShowChainsSwitcher: Bool { get }
    var navigation: Driver<ReceiveToken.NavigatableScene?> { get }
    
    func switchToken(_ tokenType: ReceiveToken.TokenType)
    func copyToClipboard(address: String, logEvent: AnalyticsEvent)
    func showSelectionNetwork()
}

extension ReceiveToken {
    class SceneModel: NSObject, ReceiveSceneModel {
        @Injected private var analyticsManager: AnalyticsManagerType
        @Injected private var clipboardManager: ClipboardManagerType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        let receiveSolanaViewModel: ReceiveTokenSolanaViewModelType
        let receiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType
        
        // MARK: - Subjects
        private let navigationSubject = PublishRelay<NavigatableScene?>()
        private let tokenTypeSubject = BehaviorRelay<TokenType>(value: .solana)
        
        init(
            solanaPubkey: SolanaSDK.PublicKey,
            solanaTokenWallet: Wallet? = nil,
            tokensRepository: TokensRepository,
            renVMService: RenVMLockAndMintServiceType,
            isRenBTCWalletCreated: Bool,
            associatedTokenAccountHandler: AssociatedTokenAccountHandler
        ) {
            receiveSolanaViewModel = ReceiveToken.SolanaViewModel(
                solanaPubkey: solanaPubkey.base58EncodedString,
                solanaTokenWallet: solanaTokenWallet,
                tokensRepository: tokensRepository,
                navigationSubject: navigationSubject
            )
            
            receiveBitcoinViewModel = ReceiveToken.ReceiveBitcoinViewModel(
                renVMService: renVMService,
                navigationSubject: navigationSubject,
                isRenBTCWalletCreated: isRenBTCWalletCreated,
                associatedTokenAccountHandler: associatedTokenAccountHandler
            )
            
            if let token = solanaTokenWallet?.token,
               token.isRenBTC {
                tokenTypeSubject.accept(.btc)
            }
        }
        
        var tokenTypeDriver: Driver<ReceiveToken.TokenType> { tokenTypeSubject.asDriver() }
        
        var updateLayoutDriver: Driver<Void> {
            Driver.combineLatest(
                    tokenTypeDriver,
                    receiveBitcoinViewModel.isReceivingRenBTCDriver,
                    receiveBitcoinViewModel.renBTCWalletCreatingDriver,
                    receiveBitcoinViewModel.conditionAcceptedDriver,
                    receiveBitcoinViewModel.addressDriver,
                    receiveBitcoinViewModel.processingTxsDriver
                )
                .map { _ in () }.asDriver()
        }
        
        func switchToken(_ tokenType: ReceiveToken.TokenType) {
            tokenTypeSubject.accept(tokenType)
        }
        
        func copyToClipboard(address: String, logEvent: AnalyticsEvent) {
            clipboardManager.copyToClipboard(address)
            analyticsManager.log(event: logEvent)
        }
        
        var shouldShowChainsSwitcher: Bool {
            receiveSolanaViewModel.tokenWallet == nil
        }
        
        func showSelectionNetwork() {
            navigationSubject.accept(.networkSelection)
        }
        
        var navigation: Driver<NavigatableScene?> { navigationSubject.asDriver(onErrorDriveWith: Driver.empty()) }
    }
}
