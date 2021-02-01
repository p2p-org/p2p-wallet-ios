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
    var wallets: [Wallet] {
        WalletsVM.ofCurrentUser.items
    }
    
    let disposeBag = DisposeBag()
    var currentPool: SolanaSDK.Pool?
    var estimatedAmount: Double?
    var minimumReceiveAmount: Double?
    
    // MARK: - ViewModels
    let poolsVM = PoolsVM(initialData: [])
    let feeVM = FeeVM(initialData: nil)
    
    // MARK: - Subjects
    let sourceWallet = BehaviorRelay<Wallet?>(value: nil)
    let destinationWallet = BehaviorRelay<Wallet?>(value: nil)
    let amount = BehaviorRelay<Double?>(value: nil)
    let slippage = BehaviorRelay<Double>(value: Defaults.slippage)
    
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
        
        Observable.combineLatest(sourceWallet, destinationWallet, amount)
            .subscribe(onNext: {_ in
                self.findCurrentPool()
                self.calculateEstimatedAndMinimumReceiveAmount()
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
    
    func calculateEstimatedAndMinimumReceiveAmount() {
        // supported
        if amount.value > 0,
           let tokenABalance = currentPool?.tokenABalance?.amountInUInt64,
           let tokenBBalance = currentPool?.tokenBBalance?.amountInUInt64,
           let sourceDecimals = sourceWallet.value?.decimals,
           let destinationDecimals = destinationWallet.value?.decimals
        {
            let inputAmount = UInt64(amount.value * pow(10, Double(sourceDecimals)))
            let slippage = self.slippage.value
            let outputAmount = SolanaSDK.calculateSwapEstimatedAmount(tokenABalance: tokenABalance, tokenBBalance: tokenBBalance, inputAmount: inputAmount)
            let estimatedAmount = Double(outputAmount) * pow(10, -Double(destinationDecimals))
            
            let minReceiveAmount = Double(SolanaSDK.calculateSwapMinimumReceiveAmount(estimatedAmount: outputAmount, slippage: slippage)) * pow(10, -Double(destinationDecimals))
            
            self.estimatedAmount = estimatedAmount
            self.minimumReceiveAmount = minReceiveAmount
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
            source: sourcePubkey,
            sourceMint: sourceMint,
            destination: destinationPubkey,
            destinationMint: destinationMint,
            slippage: slippage.value,
            amount: amountInUInt64
        )
    }
}
