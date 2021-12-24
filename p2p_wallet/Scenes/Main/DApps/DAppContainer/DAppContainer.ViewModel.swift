//
//  DAppContainer.ViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 25.11.21.
//

import Foundation
import RxSwift
import RxCocoa
import WebKit
import Resolver

protocol DAppContainerViewModelType {
    var navigationDriver: Driver<DAppContainer.NavigatableScene?> { get }
    func navigate(to scene: DAppContainer.NavigatableScene)
    
    func set(dapp: DApp)
    func getWebviewConfiguration() -> WKWebViewConfiguration
    func getDAppURL() -> String
}

extension DAppContainer {
    class ViewModel: NSObject {
        // MARK: - Dependencies
        @Injected private var dAppChannel: DAppChannel
        @Injected private var accountStorage: SolanaSDKAccountStorage
        @Injected private var walletsRepository: WalletsRepository
        
        // MARK: - Properties
        private var dapp: DApp!
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        
        override init() {
            super.init()
            dAppChannel.setDelegate(self)
        }
    }
}

extension DAppContainer.ViewModel: DAppContainerViewModelType {
    var navigationDriver: Driver<DAppContainer.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    // MARK: - Actions
    func navigate(to scene: DAppContainer.NavigatableScene) {
        navigationSubject.accept(scene)
    }
    
    func set(dapp: DApp) {
        self.dapp = dapp
    }
    
    func getWebviewConfiguration() -> WKWebViewConfiguration {
        dAppChannel.getWebviewConfiguration()
    }
    
    func getDAppURL() -> String {
        dapp.url
    }
}

extension DAppContainer.ViewModel: DAppChannelDelegate {
    func connect() -> Single<String> {
        guard let pubKey = walletsRepository.getWallets().first(where: { $0.isNativeSOL })?.pubkey else {
            return .error(DAppChannelError.canNotFindWalletAddress)
        }
        
        return .just(pubKey)
    }
    
    func signTransaction(transaction: SolanaSDK.Transaction) -> Single<SolanaSDK.Transaction> {
        do {
            var transaction = transaction
            guard let signer = accountStorage.account
                else { throw DAppChannelError.unauthorized }
            
            try transaction.sign(signers: [signer])
            return .just(transaction)
        } catch let e {
            return .error(e)
        }
    }
    
    func signTransactions(transactions: [SolanaSDK.Transaction]) -> Single<[SolanaSDK.Transaction]> {
        do {
            return .just(try transactions.map { transaction in
                var transaction = transaction
                guard let signer = accountStorage.account
                    else { throw DAppChannelError.unauthorized }
                
                try transaction.sign(signers: [signer])
                try transaction.serialize(verifySignatures: true)
                return transaction
            })
        } catch let e {
            return .error(e)
        }
    }
    
}
