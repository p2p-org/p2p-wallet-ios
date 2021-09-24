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

enum TokenSettingsNavigatableScene {
    case alert(title: String?, description: String)
    case closeConfirmation
    case processTransaction(request: Single<ProcessTransactionResponseType>, transactionType: ProcessTransaction.TransactionType)
}

class TokenSettingsViewModel: BEListViewModel<TokenSettings> {
    // MARK: - Properties
    let disposeBag = DisposeBag()
    let walletsRepository: WalletsRepository
    let pubkey: String
    let solanaSDK: SolanaSDK
    let pricesRepository: PricesRepository
    @Injected private var accountStorage: KeychainAccountStorage
    var wallet: Wallet? {walletsRepository.getWallets().first(where: {$0.pubkey == pubkey})}
    
    // MARK: - Subject
    let navigationSubject = PublishSubject<TokenSettingsNavigatableScene>()
//    private let wallet = BehaviorRelay<Wallet?>(value: nil)
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    init(
        walletsRepository: WalletsRepository,
        pubkey: String,
        solanaSDK: SolanaSDK,
        pricesRepository: PricesRepository
    ) {
        self.walletsRepository = walletsRepository
        self.pubkey = pubkey
        self.solanaSDK = solanaSDK
        self.pricesRepository = pricesRepository
        super.init()
    }
    
    override func bind() {
        super.bind()
        walletsRepository.dataObservable
            .map {$0?.first(where: {$0.pubkey == self.pubkey})}
            .map {wallet -> [TokenSettings] in
                let isWalletVisible = !(wallet?.isHidden ?? true)
                let isAmountEmpty = wallet?.amount == 0
                let isNonNativeSOL = (wallet?.token.isNative == false && wallet?.token.symbol == "SOL")
                return [
                    .visibility(isWalletVisible),
                    .close(enabled: isAmountEmpty || isNonNativeSOL)
                ]
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
