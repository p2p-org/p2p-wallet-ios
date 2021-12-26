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
    var receiveSolanaViewModel: ReceiveTokenSolanaViewModelType! { get }
    var receiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType! { get }
    var shouldShowChainsSwitcher: Bool { get }
    var navigation: Driver<ReceiveToken.NavigatableScene?> { get }
    
    func set(
        solanaPubkey: SolanaSDK.PublicKey,
        solanaTokenWallet: Wallet?,
        isRenBTCWalletCreated: Bool
    )
    
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
        var receiveSolanaViewModel: ReceiveTokenSolanaViewModelType!
        var receiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType!
        
        // MARK: - Subjects
        private let navigationSubject = PublishRelay<NavigatableScene?>()
        private let tokenTypeSubject = BehaviorRelay<TokenType>(value: .solana)
        
        func set(
            solanaPubkey: SolanaSDK.PublicKey,
            solanaTokenWallet: Wallet? = nil,
            isRenBTCWalletCreated: Bool
        ) {
            receiveSolanaViewModel = ReceiveToken.SolanaViewModel(
                solanaPubkey: solanaPubkey.base58EncodedString,
                solanaTokenWallet: solanaTokenWallet,
                navigationSubject: navigationSubject
            )
            
            receiveBitcoinViewModel = ReceiveToken.ReceiveBitcoinViewModel(
                navigationSubject: navigationSubject,
                isRenBTCWalletCreated: isRenBTCWalletCreated
            )
            
            if let token = solanaTokenWallet?.token,
               token.isRenBTC {
                tokenTypeSubject.accept(.btc)
            }
        }
        
        deinit {
            debugPrint("\(String(describing: self)) deinited")
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
