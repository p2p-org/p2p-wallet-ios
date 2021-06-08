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
    let walletsRepository: WalletsRepository
    let pubkey: String
    let symbol: String
    let graphViewModel: WalletGraphViewModel
    
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
        walletsRepository: WalletsRepository,
        pricesRepository: PricesRepository,
        transactionsRepository: TransactionsRepository
    ) {
        self.walletsRepository = walletsRepository
        self.pubkey = walletPubkey
        self.symbol = walletSymbol
        self.transactionsViewModel = TransactionsViewModel(account: walletPubkey, accountSymbol: walletSymbol, repository: transactionsRepository, pricesRepository: pricesRepository)
        self.graphViewModel = WalletGraphViewModel(symbol: walletSymbol, pricesRepository: pricesRepository)
        bind()
    }
    
    func bind() {
        walletsRepository.dataObservable
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
