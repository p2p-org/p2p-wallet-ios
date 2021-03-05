//
//  WalletDetailViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/03/2021.
//

import UIKit
import RxSwift
import RxCocoa

enum WalletDetailNavigatableScene {
    case settings
    case send
    case receive
    case swap
    case transactionInfo(_ transaction: Transaction)
}

class WalletDetailTransactionsVM: WalletTransactionsVM {
    let graphVM: WalletGraphVM
    
    override init(solanaSDK: SolanaSDK, walletsVM: WalletsVM, pubkey: String, symbol: String) {
        graphVM = WalletGraphVM(symbol: symbol)
        super.init(solanaSDK: solanaSDK, walletsVM: walletsVM, pubkey: pubkey, symbol: symbol)
    }
    
    override func reload() {
        graphVM.reload()
        super.reload()
    }
}

class WalletDetailViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    let solanaSDK: SolanaSDK
    let walletsVM: WalletsVM
    let pubkey: String
    
    let transactionsVM: WalletDetailTransactionsVM
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<WalletDetailNavigatableScene>()
    let wallet = BehaviorRelay<Wallet?>(value: nil)
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Initializers
    init(solanaSDK: SolanaSDK, walletsVM: WalletsVM, walletPubkey: String, walletSymbol: String) {
        self.solanaSDK = solanaSDK
        self.walletsVM = walletsVM
        self.pubkey = walletPubkey
        self.transactionsVM = WalletDetailTransactionsVM(solanaSDK: solanaSDK, walletsVM: walletsVM, pubkey: pubkey, symbol: walletSymbol)
        bind()
    }
    
    func bind() {
        walletsVM.dataObservable
            .map {$0?.first(where: {$0.pubkey == self.pubkey})}
            .bind(to: wallet)
            .disposed(by: disposeBag)
    }
    // MARK: - Actions
    @objc func showWalletSettings() {
        navigationSubject.onNext(.settings)
    }
    
    @objc func sendTokens() {
        navigationSubject.onNext(.send)
    }
    
    @objc func receiveTokens() {
        navigationSubject.onNext(.receive)
    }
    
    @objc func swapTokens() {
        navigationSubject.onNext(.swap)
    }
}
