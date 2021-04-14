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
    case processTransaction
}

class TokenSettingsViewModel: BEListViewModel<TokenSettings> {
    // MARK: - Properties
    let disposeBag = DisposeBag()
    let walletsRepository: WalletsRepository
    let pubkey: String
    let solanaSDK: SolanaSDK
    let transactionManager: TransactionsManager
    let accountStorage: KeychainAccountStorage
    var wallet: Wallet? {walletsRepository.getWallets().first(where: {$0.pubkey == pubkey})}
    lazy var processTransactionViewModel: ProcessTransactionViewModel = {
        let viewModel = ProcessTransactionViewModel(transactionsManager: transactionManager)
        viewModel.tryAgainAction = CocoaAction {
            self.closeWallet()
            return .just(())
        }
        return viewModel
    }()
    
    // MARK: - Subject
    let navigationSubject = PublishSubject<TokenSettingsNavigatableScene>()
//    private let wallet = BehaviorRelay<Wallet?>(value: nil)
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    init(walletsRepository: WalletsRepository, pubkey: String, solanaSDK: SolanaSDK, transactionManager: TransactionsManager, accountStorage: KeychainAccountStorage) {
        self.walletsRepository = walletsRepository
        self.pubkey = pubkey
        self.solanaSDK = solanaSDK
        self.transactionManager = transactionManager
        self.accountStorage = accountStorage
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
    
    @objc func showProcessingAndClose() {
        navigationSubject.onNext(.processTransaction)
        closeWallet()
    }
    
    private func closeWallet() {
        var transaction = Transaction(
            type: .send,
            symbol: "SOL",
            status: .processing
        )
        
        self.processTransactionViewModel.transactionInfo.accept(
            TransactionInfo(transaction: transaction)
        )
        
        Single.zip(
            solanaSDK.closeTokenAccount(tokenPubkey: pubkey),
            solanaSDK.getCreatingTokenAccountFee().catchAndReturn(0)
        )
            .subscribe(onSuccess: { signature, fee in
                transaction.amount = fee.convertToBalance(decimals: 9)
                transaction.signatureInfo = .init(signature: signature)
                self.processTransactionViewModel.transactionInfo.accept(
                    TransactionInfo(transaction: transaction)
                )
                self.transactionManager.process(transaction)
                _ = self.walletsRepository.removeItem(where: {$0.pubkey == self.pubkey})
            }, onFailure: {error in
                self.processTransactionViewModel.transactionInfo.accept(
                    TransactionInfo(transaction: transaction, error: error)
                )
            })
            .disposed(by: disposeBag)
    }
}
