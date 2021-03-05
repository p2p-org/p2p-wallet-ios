//
//  TokenSettingsViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/02/2021.
//

import UIKit
import RxSwift
import RxCocoa

enum TokenSettingsNavigatableScene {
    case closeConfirmation
    case sendTransaction
    case processTransaction(signature: String)
    case transactionError(_ error: Error)
}

class TokenSettingsViewModel: ListViewModel<TokenSettings> {
    // MARK: - Properties
    let walletsVM: WalletsVM
    let pubkey: String
    let solanaSDK: SolanaSDK
    let transactionManager: TransactionsManager
    let accountStorage: KeychainAccountStorage
    var wallet: Wallet? {walletsVM.items.first(where: {$0.pubkey == pubkey})}
    
    // MARK: - Subject
    let navigationSubject = PublishSubject<TokenSettingsNavigatableScene>()
//    private let wallet = BehaviorRelay<Wallet?>(value: nil)
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    init(walletsVM: WalletsVM, pubkey: String, solanaSDK: SolanaSDK, transactionManager: TransactionsManager, accountStorage: KeychainAccountStorage) {
        self.walletsVM = walletsVM
        self.pubkey = pubkey
        self.solanaSDK = solanaSDK
        self.transactionManager = transactionManager
        self.accountStorage = accountStorage
        super.init()
    }
    
    override func bind() {
        super.bind()
        walletsVM.dataObservable
            .map {$0?.first(where: {$0.pubkey == self.pubkey})}
            .map {wallet -> [TokenSettings] in
                [
                    .visibility(!(wallet?.isHidden ?? false)),
                    .close
                ]
            }
            .subscribe(onNext: { (settings) in
                self.items = settings
                self.state.accept(.loaded(settings))
            })
            .disposed(by: disposeBag)
    }
    
    override func reload() {}
    
    // MARK: - Actions
    @objc func toggleHideWallet() {
        guard let wallet = wallet else {return}
        if wallet.isHidden {
            walletsVM.unhideWallet(wallet)
        } else {
            walletsVM.hideWallet(wallet)
        }
    }
    
    @objc func closeWallet() {
        navigationSubject.onNext(.sendTransaction)
        Single.zip(
            solanaSDK.closeTokenAccount(tokenPubkey: pubkey),
            solanaSDK.getCreatingTokenAccountFee().catchErrorJustReturn(0)
        )
            .subscribe(onSuccess: { signature, fee in
                self.navigationSubject.onNext(.processTransaction(signature: signature))
                let transaction = Transaction(
                    signatureInfo: .init(signature: signature),
                    type: .send,
                    amount: +fee.convertToBalance(decimals: 9),
                    symbol: "SOL",
                    status: .processing
                )
                self.transactionManager.process(transaction)
                self.walletsVM.removeItem(where: {$0.pubkey == self.pubkey})
            }, onError: {error in
                self.navigationSubject.onNext(.transactionError(error))
            })
            .disposed(by: disposeBag)
    }
}
