//
//  SwapTokenVM.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/01/2021.
//

import Foundation
import RxSwift
import RxCocoa

class SwapTokenVM {
    // MARK: - Nested type
    class PoolsVM: BaseVM<[SolanaSDK.Pool]> {
        override var request: Single<[SolanaSDK.Pool]> {
            SolanaSDK.shared.getSwapPools()
        }
    }

    class FeeVM: BaseVM<Double?> {
        override var request: Single<Double?> {
            SolanaSDK.shared.getMinimumBalanceForRentExemption(dataLength: UInt64(SolanaSDK.AccountInfo.BUFFER_LENGTH))
                .map {Double($0) * pow(10, -9)}
        }
    }
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    var currentPool: SolanaSDK.Pool?
    var wallets: [Wallet] {
        WalletsVM.ofCurrentUser.items
    }
    
    // MARK: - ViewModels
    let poolsVM = PoolsVM(initialData: [])
    let feeVM = FeeVM(initialData: nil)
    
    // MARK: - Subjects
    let sourceWallet = BehaviorRelay<Wallet?>(value: nil)
    let destinationWallet = BehaviorRelay<Wallet?>(value: nil)
    let amount = BehaviorRelay<Double?>(value: nil)
    let slippage = BehaviorRelay<Double>(value: 0.1)
    
    init() {
        poolsVM.reload()
        feeVM.reload()
        bind()
    }
    
    func bind() {
        poolsVM.dataDidChange
            .subscribe(onNext: { [weak self] in
                self?.findCurrentPool()
            })
            .disposed(by: disposeBag)
        
        Observable.combineLatest(sourceWallet, destinationWallet)
            .subscribe(onNext: {_ in
                self.findCurrentPool()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Helpers
    private func findCurrentPool() {
        self.currentPool = poolsVM.data.first(
            where: {
                $0.swapData.mintA.base58EncodedString == self.sourceWallet.value?.mintAddress &&
                    $0.swapData.mintB.base58EncodedString == self.destinationWallet.value?.mintAddress
            }
        )
    }
}
