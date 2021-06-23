//
//  ReceiveToken.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/06/2021.
//

import Foundation
import RxSwift
import RxCocoa

extension ReceiveToken {
    class ViewModel: ViewModelType {
        // MARK: - Nested type
        struct Input {
            
        }
        struct Output {
            let navigationScene: Driver<NavigatableScene?>
            let isShowingDetail: Driver<Bool>
            let pubkey: String
            let tokenWallet: Wallet?
        }
        
        // MARK: - Dependencies
        private let pubkey: String
        private let tokenWallet: Wallet?
        private let analyticsManager: AnalyticsManagerType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        
        let input: Input
        let output: Output
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let isShowingDetailSubject = BehaviorRelay<Bool>(value: false)
        
        // MARK: - Initializer
        init(pubkey: String, tokenWallet: Wallet? = nil, analyticsManager: AnalyticsManagerType) {
            self.pubkey = pubkey
            self.analyticsManager = analyticsManager
            var tokenWallet = tokenWallet
            if tokenWallet?.pubkey == pubkey {
                tokenWallet = nil
            }
            self.tokenWallet = tokenWallet
            
            self.input = Input()
            self.output = Output(
                navigationScene: navigationSubject
                    .asDriver(onErrorJustReturn: nil),
                isShowingDetail: isShowingDetailSubject
                    .asDriver(),
                pubkey: pubkey,
                tokenWallet: tokenWallet
            )
        }
        
        // MARK: - Actions
        @objc func showSOLAddressInExplorer() {
            analyticsManager.log(event: .receiveViewExplorerOpen)
            navigationSubject.accept(.showInExplorer(address: pubkey))
        }
        
        @objc func showTokenMintAddressInExplorer() {
            guard let mintAddress = tokenWallet?.token.address else {return}
            analyticsManager.log(event: .receiveViewExplorerOpen)
            navigationSubject.accept(.showInExplorer(address: mintAddress))
        }
        
        @objc func showTokenPubkeyAddressInExplorer() {
            guard let pubkey = tokenWallet?.pubkey else {return}
            analyticsManager.log(event: .receiveViewExplorerOpen)
            navigationSubject.accept(.showInExplorer(address: pubkey))
        }
        
        @objc func share() {
            analyticsManager.log(event: .receiveAddressShare)
            navigationSubject.accept(.share(address: pubkey))
        }
        
        @objc func showHelp() {
            navigationSubject.accept(.help)
        }
        
        @objc func toggleIsShowingDetail() {
            isShowingDetailSubject.accept(!isShowingDetailSubject.value)
        }
        
        func copyToClipboard(address: String, logEvent: AnalyticsEvent) {
            UIApplication.shared.copyToClipboard(address, alert: false)
            analyticsManager.log(event: logEvent)
        }
    }
}
