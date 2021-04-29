//
//  ReceiveTokenViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/03/2021.
//

import UIKit
import RxSwift
import RxCocoa
import LazySubject

enum ReceiveTokenNavigatableScene {
    case chooseWallet
    case explorer(url: String)
    case share(pubkey: String)
}

class ReceiveTokenViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    let repository: WalletsRepository
    let createTokenHandler: CreateTokenHandler
    let transactionHandler: TransactionHandler
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<ReceiveTokenNavigatableScene>()
    let wallet = BehaviorRelay<Wallet?>(value: nil)
    let alert = PublishSubject<String>()
    lazy var feeSubject = LazySubject(
        value: Double(0),
        request: createTokenHandler.getCreatingTokenAccountFee()
            .map {
                Double($0) * pow(Double(10), -Double(9))
            }
    )
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Initializers
    init(
        createTokenHandler: CreateTokenHandler,
        transactionHandler: TransactionHandler,
        walletsRepository: WalletsRepository,
        pubkey: String? = nil
    ) {
        self.repository = walletsRepository
        self.createTokenHandler = createTokenHandler
        self.transactionHandler = transactionHandler
        self.wallet.accept(repository.getWallets().first(where: {$0.pubkey == pubkey}) ?? repository.getWallets().first)
        bind()
    }
    
    private func bind() {
        // bind wallet
        repository.stateObservable
            .filter { state in
                switch state {
                case .loaded:
                    return true
                default:
                    return false
                }
            }
            .take(1)
            .map { [weak self] _ -> Wallet? in
                if let currentWallet = self?.wallet.value {
                    return self?.repository.getWallets().first(where: {$0.pubkey == currentWallet.pubkey})
                }
                return self?.repository.getWallets().first
            }
            .bind(to: wallet)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Actions
    @objc func selectWallet() {
        navigationSubject.onNext(.chooseWallet)
    }
    
    @objc func showMintInExplorer() {
        guard let mint = wallet.value?.mintAddress else {return}
        let url = "https://explorer.solana.com/address/\(mint)"
        navigationSubject.onNext(.explorer(url: url))
    }
    
    @objc func share() {
        guard let pubkey = wallet.value?.pubkey else {return}
        navigationSubject.onNext(.share(pubkey: pubkey))
    }
    
    @objc func createWallet() {
        guard var wallet = wallet.value else {return}
        // insufficient funds
        if self.feeSubject.value > (self.repository.solWallet?.amount ?? 0) {
            wallet.creatingError = L10n.insufficientFunds
            wallet.isBeingCreated = false
            self.wallet.accept(wallet)
            return
        }
        
        // set up loading
        wallet.isBeingCreated = true
        wallet.creatingError = nil
        self.wallet.accept(wallet)
        
        // request
        createTokenHandler.createTokenAccount(mintAddress: wallet.mintAddress, isSimulation: false)
            .flatMap {
                self.transactionHandler.observeTransactionCompletion(signature: $0.signature)
                    .andThen(.just($0))
            }
            .subscribe(onSuccess: {
                wallet.pubkey = $0.newPubkey
                wallet.isBeingCreated = false
                self.wallet.accept(wallet)
            }, onFailure: {error in
                wallet.creatingError = error.readableDescription
                wallet.isBeingCreated = false
                self.wallet.accept(wallet)
            })
            .disposed(by: disposeBag)
    }
    
    func setCurrentWallet(_ wallet: Wallet) {
        var wallet = wallet
        if wallet.pubkey == nil,
           let solPubkeyString = repository.solWallet?.pubkey,
           let solPubkey = try? SolanaSDK.PublicKey(string: solPubkeyString),
           let mint = try? SolanaSDK.PublicKey(string: wallet.token.address)
        {
            let associatedTokenAddress =
                try? SolanaSDK.PublicKey.associatedTokenAddress(
                    walletAddress: solPubkey,
                    tokenMintAddress: mint
                )
            wallet.pubkey = associatedTokenAddress?.base58EncodedString
        }
        self.wallet.accept(wallet)
    }
}
