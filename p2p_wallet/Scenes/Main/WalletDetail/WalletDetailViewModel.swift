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
}

class WalletDetailViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    let solanaSDK: SolanaSDK
    let walletsVM: WalletsVM
    let pubkey: String
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<WalletDetailNavigatableScene>()
    let wallet = BehaviorRelay<Wallet?>(value: nil)
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Initializers
    init(solanaSDK: SolanaSDK, walletsVM: WalletsVM, walletPubkey: String) {
        self.solanaSDK = solanaSDK
        self.walletsVM = walletsVM
        self.pubkey = walletPubkey
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
