//
//  TokenSettingsViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/02/2021.
//

import UIKit
import RxSwift
import RxCocoa
import Action
import BECollectionView
import Resolver

enum TokenSettingsNavigatableScene {
    case alert(title: String?, description: String)
    case closeConfirmation
    case processTransaction(request: Single<ProcessTransactionResponseType>, transactionType: ProcessTransaction.TransactionType)
}

class TokenSettingsViewModel: BEListViewModel<TokenSettings> {
    // MARK: - Dependencies
    @Injected private var walletsRepository: WalletsRepository
    @Injected private var solanaSDK: SolanaSDK
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    let pubkey: String
    var wallet: Wallet? {walletsRepository.getWallets().first(where: {$0.pubkey == pubkey})}
    
    // MARK: - Subject
    let navigationSubject = PublishSubject<TokenSettingsNavigatableScene>()
//    private let wallet = BehaviorRelay<Wallet?>(value: nil)
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    init(pubkey: String) {
        self.pubkey = pubkey
        super.init()
    }
    
    deinit {
        debugPrint("\(String(describing: self)) deinited")
    }
    
    override func bind() {
        super.bind()
        walletsRepository.dataObservable
            .map {[weak self] in $0?.first(where: {$0.pubkey == self?.pubkey})}
            .map {wallet -> [TokenSettings] in
                let isWalletVisible = !(wallet?.isHidden ?? true)
                let isAmountEmpty = wallet?.amount == 0
                let isNonNativeSOL = (wallet?.token.isNative == false && wallet?.token.symbol == "SOL")
                
                var options: [TokenSettings] = [
                    .visibility(isWalletVisible)
                ]
                
                #if DEBUG
                options.append(.close(enabled: isAmountEmpty || isNonNativeSOL))
                #endif
                return options
            }
            .asDriver(onErrorJustReturn: [])
            .drive(onNext: { [weak self] (settings) in
                self?.overrideData(by: settings)
            })
            .disposed(by: disposeBag)
    }
    
    override func reload() {}
    
    // MARK: - Actions
    @objc func toggleHideWallet() {
        guard let wallet = wallet else {return}
        walletsRepository.toggleWalletVisibility(wallet)
    }
    
    @objc func closeAccount() {
        guard let wallet = wallet else {return}
        let request = solanaSDK.closeTokenAccount(tokenPubkey: pubkey)
            .map {$0 as ProcessTransactionResponseType}
        navigationSubject.onNext(.processTransaction(request: request, transactionType: .closeAccount(wallet)))
    }
}
