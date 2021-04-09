//
//  WalletDetailViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/03/2021.
//

import UIKit
import RxSwift
import RxCocoa
import BECollectionView

enum WalletDetailNavigatableScene {
    case settings
    case send
    case receive
    case swap
    case transactionInfo(_ transaction: SolanaSDK.AnyTransaction)
}

class WalletDetailViewModel {
    // MARK: - Constants
    let disposeBag = DisposeBag()
    
    // MARK: - Properties
    let solanaSDK: SolanaSDK
    let walletsRepository: WalletsRepository
    let pubkey: String
    let symbol: String
    let graphViewModel: WalletGraphVM
    
    let transactionsViewModel: TransactionsViewModel
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<WalletDetailNavigatableScene>()
    let wallet = BehaviorRelay<Wallet?>(value: nil)
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Initializers
    init(
        walletPubkey: String,
        walletSymbol: String,
        solanaSDK: SolanaSDK,
        walletsRepository: WalletsRepository,
        pricesRepository: PricesRepository
    ) {
        self.solanaSDK = solanaSDK
        self.walletsRepository = walletsRepository
        self.pubkey = walletPubkey
        self.symbol = walletSymbol
        self.transactionsViewModel = TransactionsViewModel(account: walletPubkey, accountSymbol: walletSymbol, repository: solanaSDK, pricesRepository: pricesRepository)
        self.graphViewModel = WalletGraphVM(symbol: walletSymbol)
        bind()
    }
    
    func bind() {
        walletsRepository.dataObservable
            .map {$0?.first(where: {$0.pubkey == self.pubkey})}
            .bind(to: wallet)
            .disposed(by: disposeBag)
        
        transactionsViewModel.stateObservable
            .map {$0 == .loading}
            .subscribe(onNext: {[weak self] _ in
                self?.graphViewModel.reload()
            })
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
