//
//  ReceiveToken.ReceiveSolanaViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/09/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol ReceiveTokenSolanaViewModelType {
    var isShowingDetailDriver: Driver<Bool> {get}
    var pubkey: String {get}
    var tokenWallet: Wallet? {get}
    var tokensCountDriver: Driver<Int> {get}
    
    func getUsername() -> String?
    func showSOLAddressInExplorer()
    func showTokenMintAddressInExplorer()
    func showTokenPubkeyAddressInExplorer()
    func shareName()
    func sharePubkey()
    func showHelp()
    func toggleIsShowingDetail()
    func copyToClipboard(address: String, logEvent: AnalyticsEvent)
}

extension ReceiveToken {
    class ReceiveSolanaViewModel {
        // MARK: - Dependencies
        @Injected private var accountStorage: KeychainAccountStorage
        @Injected private var analyticsManager: AnalyticsManagerType
        private let tokensRepository: TokensRepository
        private let navigationSubject: BehaviorRelay<NavigatableScene?>
        
        // MARK: - Properties
        let pubkey: String
        let tokenWallet: Wallet?
        private let disposeBag = DisposeBag()
        
        // MARK: - Subjects
        private let isShowingDetailSubject = BehaviorRelay<Bool>(value: false)
        
        // MARK: - Initializers
        init(
            solanaPubkey: String,
            solanaTokenWallet: Wallet? = nil,
            tokensRepository: TokensRepository,
            navigationSubject: BehaviorRelay<NavigatableScene?>
        ) {
            self.pubkey = solanaPubkey
            self.tokensRepository = tokensRepository
            var tokenWallet = solanaTokenWallet
            if solanaTokenWallet?.pubkey == solanaPubkey {
                tokenWallet = nil
            }
            self.tokenWallet = tokenWallet
            self.navigationSubject = navigationSubject
        }
    }
}

extension ReceiveToken.ReceiveSolanaViewModel: ReceiveTokenSolanaViewModelType {
    var isShowingDetailDriver: Driver<Bool> {
        isShowingDetailSubject.asDriver()
    }
    
    var tokensCountDriver: Driver<Int> {
        tokensRepository.getTokensList()
            .map {$0.count}
            .asDriver(onErrorJustReturn: 554)
    }
    
    func getUsername() -> String? {
        accountStorage.getName()
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
    
    func shareName() {
        analyticsManager.log(event: .receiveNameShare)
        navigationSubject.accept(.share(address: getUsername()?.withNameServiceDomain() ?? ""))
    }
    
    func sharePubkey() {
        analyticsManager.log(event: .receiveAddressShare)
        navigationSubject.accept(.share(address: pubkey))
    }
    
    func showHelp() {
        navigationSubject.accept(.help)
    }
    
    func toggleIsShowingDetail() {
        isShowingDetailSubject.accept(!isShowingDetailSubject.value)
    }
    
    func copyToClipboard(address: String, logEvent: AnalyticsEvent) {
        UIApplication.shared.copyToClipboard(address, alert: false)
        analyticsManager.log(event: logEvent)
    }
}
