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
    case processTransaction(request: Single<SolanaSDK.TransactionID>, transactionType: ProcessTransaction.TransactionType)
}

class TokenSettingsViewModel: BEListViewModel<TokenSettings> {
    // MARK: - Properties
    let disposeBag = DisposeBag()
    let walletsRepository: WalletsRepository
    let pubkey: String
    let solanaSDK: SolanaSDK
    let pricesRepository: PricesRepository
    let accountStorage: KeychainAccountStorage
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
        pricesRepository: PricesRepository,
        accountStorage: KeychainAccountStorage
    ) {
        self.walletsRepository = walletsRepository
        self.pubkey = pubkey
        self.solanaSDK = solanaSDK
        self.accountStorage = accountStorage
        self.pricesRepository = pricesRepository
        super.init()
    }
    
    override func bind() {
        super.bind()
        walletsRepository.dataObservable
            .map {$0?.first(where: {$0.pubkey == self.pubkey})}
            .map {wallet -> [TokenSettings] in
                [
                    .visibility(!(wallet?.isHidden ?? false)),
                    .close(enabled: wallet?.amount == 0)
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
        navigationSubject.onNext(.processTransaction(request: request, transactionType: .closeAccount(wallet)))
    }
}
