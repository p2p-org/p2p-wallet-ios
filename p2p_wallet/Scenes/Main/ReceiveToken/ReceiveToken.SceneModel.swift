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
    
    func switchToken(_ tokenType: ReceiveToken.TokenType)
    func copyToClipboard(address: String, logEvent: AnalyticsEvent)
}

extension ReceiveToken {
    class SceneModel: NSObject, ReceiveSceneModel {
        
        @Injected private var analyticsManager: AnalyticsManagerType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        let receiveSolanaViewModel: ReceiveTokenSolanaViewModelType
        let receiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType
        
        // MARK: - Subjects
        private let navigationSubject = PublishSubject<NavigatableScene>()
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
        
        var tokenTypeDriver: Driver<ReceiveToken.TokenType> {
            tokenTypeSubject.asDriver()
        }
        
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
            UIApplication.shared.copyToClipboard(address, alert: false)
            analyticsManager.log(event: logEvent)
        }
        
        var shouldShowChainsSwitcher: Bool {
            receiveSolanaViewModel.tokenWallet == nil
        }
    }
}

extension ReceiveToken.SceneModel: BESceneNavigationModel {
    // MARK: - Navigation
    var navigationDriver: Driver<NavigationType> {
        navigationSubject.map { [weak self] scene in
            guard let self = self else { return .none }
            switch scene {
            case .showInExplorer(let mintAddress):
                let url = "https://explorer.solana.com/address/\(mintAddress)"
                guard let vc = WebViewController.inReaderMode(url: url) else { return .none }
                return .modal(vc)
            case .showBTCExplorer(let address):
                let url = "https://btc.com/btc/address/\(address)"
                guard let vc = WebViewController.inReaderMode(url: url) else { return .none }
                return .modal(vc)
            case .chooseBTCOption(let selectedOption):
                let vc = ReceiveToken.SelectBTCTypeViewController(viewModel: self.receiveBitcoinViewModel, selectedOption: selectedOption)
                return .modal(vc)
            case .showRenBTCReceivingStatus:
                let vm = RenBTCReceivingStatuses.ViewModel(receiveBitcoinViewModel: self.receiveBitcoinViewModel)
                let vc = RenBTCReceivingStatuses.ViewController(viewModel: vm)
                let nc = FlexibleHeightNavigationController(rootViewController: vc)
                return .modal(nc)
            case .share(let address, let qrCode):
                if let qrCode = qrCode {
                    let vc = UIActivityViewController(activityItems: [qrCode], applicationActivities: nil)
                    return .modal(vc)
                } else if let address = address {
                    let vc = UIActivityViewController(activityItems: [address], applicationActivities: nil)
                    return .modal(vc)
                }
            case .help:
                return .modal(ReceiveToken.HelpViewController())
            }
            return .none
        }.asDriver(onErrorJustReturn: .none)
    }
}

