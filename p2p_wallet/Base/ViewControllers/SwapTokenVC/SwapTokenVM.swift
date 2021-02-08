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
    
    // MARK: - Properties
    var wallets: [Wallet] {
        WalletsVM.ofCurrentUser.items
    }
    
    let disposeBag = DisposeBag()
    var currentPool: SolanaSDK.Pool?
    var estimatedAmount: Double?
    var minimumReceiveAmount: Double?
    
    // MARK: - ViewModels
    let poolsVM = PoolsVM(initialData: [])
    
    // MARK: - Subjects
    let sourceWallet = BehaviorRelay<Wallet?>(value: nil)
    let destinationWallet = BehaviorRelay<Wallet?>(value: nil)
    let amount = BehaviorRelay<Double?>(value: nil)
    let slippage = BehaviorRelay<Double>(value: Defaults.slippage)
    
    init() {
        poolsVM.reload()
        bind()
    }
    
    func bind() {
        poolsVM.dataDidChange
            .subscribe(onNext: { [weak self] in
                self?.findCurrentPool()
            })
            .disposed(by: disposeBag)
        
        Observable.combineLatest(sourceWallet, destinationWallet, amount)
            .subscribe(onNext: {_ in
                self.findCurrentPool()
                self.calculateEstimatedAndMinimumReceiveAmount()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Helpers
    private func findCurrentPool() {
        self.currentPool = poolsVM.data.matchedPool(
            sourceMint: sourceWallet.value?.mintAddress,
            destinationMint: destinationWallet.value?.mintAddress
        )
    }
    
    func calculateEstimatedAndMinimumReceiveAmount() {
        // supported
        if amount.value > 0,
           let sourceDecimals = sourceWallet.value?.decimals,
           let destinationDecimals = destinationWallet.value?.decimals,
           let inputLamports = amount.value?.toLamport(decimals: sourceDecimals),
           let estimatedAmountLamports = currentPool?.estimatedAmount(forInputAmount: inputLamports),
           let minimumReceiveAmountLamports = currentPool?.minimumReceiveAmount(estimatedAmount: estimatedAmountLamports, slippage: slippage.value)
        {
            self.estimatedAmount = estimatedAmountLamports.convertToBalance(decimals: destinationDecimals)
            self.minimumReceiveAmount = minimumReceiveAmountLamports.convertToBalance(decimals: destinationDecimals)
        }
    }
    
    func swap() -> Single<String> {
        guard let sourceWallet = sourceWallet.value,
              let sourcePubkey = try? SolanaSDK.PublicKey(string: sourceWallet.pubkey ?? ""),
              let sourceMint = try? SolanaSDK.PublicKey(string: sourceWallet.mintAddress),
              let destinationWallet = destinationWallet.value,
              let destinationMint = try? SolanaSDK.PublicKey(string: destinationWallet.mintAddress),
              
              let sourceDecimals = sourceWallet.decimals,
              let amountDouble = amount.value
        else {
            return .error(SolanaSDK.Error.other("Params are not valid"))
        }
        let amountInUInt64 = UInt64(amountDouble * pow(10, Double(sourceDecimals)))
        let destinationPubkey = try? SolanaSDK.PublicKey(string: destinationWallet.pubkey ?? "")
        return SolanaSDK.shared.swap(
            pool: currentPool,
            source: sourcePubkey,
            sourceMint: sourceMint,
            destination: destinationPubkey,
            destinationMint: destinationMint,
            slippage: slippage.value,
            amount: amountInUInt64
        )
    }
}
