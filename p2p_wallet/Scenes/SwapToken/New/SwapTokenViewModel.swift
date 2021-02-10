//
//  SwapTokenViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/02/2021.
//

import UIKit
import RxSwift
import RxCocoa
import LazySubject

enum SwapTokenNavigatableScene {
//    case detail
}

class SwapTokenViewModel {
    // MARK: - Constants
    typealias Pool = SolanaSDK.Pool
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    let wallets: [Wallet]
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<SwapTokenNavigatableScene>()
    let pools = LazySubject<[Pool]>(request: SolanaSDK.shared.getSwapPools())
    let currentPool = BehaviorRelay<Pool?>(value: nil)
    let estimatedAmount = BehaviorRelay<Double?>(value: nil)
    let minimumReceiveAmount = BehaviorRelay<Double?>(value: nil)
    
    // MARK: - Input
    let amountInput = BehaviorRelay<Double?>(value: nil)
    let sourceWallet = BehaviorRelay<Wallet?>(value: nil)
    let destinationWallet = BehaviorRelay<Wallet?>(value: nil)
    let slippage = BehaviorRelay<Double>(value: Defaults.slippage)
    
    // MARK: - Initializer
    init(wallets: [Wallet]) {
        self.wallets = wallets
        pools.reload()
        bind()
    }
    
    // MARK: - Binding
    func bind() {
        let poolsLoaded =
        pools.observable
            .filter {$0 == .loaded}
            .map {_ in self.pools.value}
        
        // current pool
        Observable.combineLatest(
            poolsLoaded,
            sourceWallet.distinctUntilChanged(),
            destinationWallet.distinctUntilChanged()
        )
            .map {(pools, sourceWallet, destinationWallet) in
                pools?.matchedPool(
                    sourceMint: sourceWallet?.mintAddress,
                    destinationMint: destinationWallet?.mintAddress
                )
            }
            .bind(to: currentPool)
            .disposed(by: disposeBag)
        
        // estimated amount
        let estimatedAmountLamports = Observable.combineLatest(
            currentPool.distinctUntilChanged(),
            amountInput.distinctUntilChanged()
        )
            .map {(pool, amount) -> UInt64? in
                guard let amount = amount,
                      amount > 0,
                      let sourceDecimals = self.sourceWallet.value?.decimals,
                      let estimatedAmountLamports = pool?.estimatedAmount(forInputAmount: amount.toLamport(decimals: sourceDecimals))
                else {return nil}
                return estimatedAmountLamports
            }
            
        estimatedAmountLamports
            .map {lamports -> Double? in
                guard let destinationDecimals = self.destinationWallet.value?.decimals
                else {return nil}
                return lamports?.convertToBalance(decimals: destinationDecimals)
            }
            .bind(to: estimatedAmount)
            .disposed(by: disposeBag)
        
        // minimum receive
        Observable.combineLatest(
            estimatedAmountLamports.distinctUntilChanged(),
            slippage.distinctUntilChanged()
        )
            .map {(estimatedAmountLamports, slippage) -> Double? in
                guard let estimatedAmountLamports = estimatedAmountLamports,
                      let lamports = self.currentPool.value?.minimumReceiveAmount(estimatedAmount: estimatedAmountLamports, slippage: slippage),
                      let destinationDecimals = self.destinationWallet.value?.decimals
                else {return nil}
                return lamports.convertToBalance(decimals: destinationDecimals)
            }
            .bind(to: minimumReceiveAmount)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Actions
//    @objc func showDetail() {
//        
//    }
}
