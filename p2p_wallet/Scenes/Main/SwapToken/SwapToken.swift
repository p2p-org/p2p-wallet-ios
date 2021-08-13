//
//  SwapToken.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/06/2021.
//

import Foundation
import RxSwift
import FeeRelayerSwift

protocol SwapTokenAPIClient {
    func getSwapPools() -> Single<[SolanaSDK.Pool]>
    func getPoolWithTokenBalances(pool: SolanaSDK.Pool) -> Single<SolanaSDK.Pool>
    func swap(
        account: SolanaSDK.Account?,
        pool: SolanaSDK.Pool?,
        source: SolanaSDK.PublicKey,
        sourceMint: SolanaSDK.PublicKey,
        destination: SolanaSDK.PublicKey?,
        destinationMint: SolanaSDK.PublicKey,
        slippage: Double,
        amount: UInt64,
        isSimulation: Bool
    ) -> Single<SolanaSDK.SwapResponse>
    func getLamportsPerSignature() -> Single<SolanaSDK.Lamports>
    func getCreatingTokenAccountFee() -> Single<UInt64>
}

extension SolanaSDK: SwapTokenAPIClient {
    func swap(account: Account?, pool: Pool?, source: PublicKey, sourceMint: PublicKey, destination: PublicKey?, destinationMint: PublicKey, slippage: Double, amount: UInt64, isSimulation: Bool) -> Single<SwapResponse> {
        swap(
            account: account,
            pool: pool,
            source: source,
            sourceMint: sourceMint,
            destination: destination,
            destinationMint: destinationMint,
            slippage: slippage,
            amount: amount,
            isSimulation: isSimulation,
            customProxy: Defaults.payingToken == .transactionToken ? FeeRelayer(): nil
        )
    }
    
    func getLamportsPerSignature() -> Single<Lamports> {
        getFees().map {$0.feeCalculator?.lamportsPerSignature}.map {$0 ?? 0}
    }
}

struct SwapToken {
    enum NavigatableScene {
        case chooseSourceWallet
        case chooseDestinationWallet(validMints: Set<String>, excludedSourceWalletPubkey: String?)
        case chooseSlippage
        case processTransaction(request: Single<ProcessTransactionResponseType>, transactionType: ProcessTransaction.TransactionType)
    }
    
    // MARK: - Helpers
    static func isFeeRelayerEnabled(source: Wallet?, destination: Wallet?) -> Bool {
        guard let source = source,
              let destination = destination
        else {
            return false
        }
        return !source.token.isNative && !destination.token.isNative
    }
    
    static func createSectionView(
        title: String? = nil,
        label: UIView? = nil,
        contentView: UIView,
        rightView: UIView = UIImageView(width: 6, height: 12, image: .nextArrow, tintColor: .h8b94a9.onDarkMode(.white)
        )
            .padding(.init(x: 9, y: 6))
    ) -> UIStackView {
        UIStackView(axis: .vertical, spacing: 16, alignment: .fill, distribution: .fill) {
            UIView.defaultSeparator()
            UIStackView(axis: .horizontal, spacing: 5, alignment: .center, distribution: .fill) {
                UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill) {
                    label ?? UILabel(
                        text: title,
                        textSize: 13,
                        weight: .medium,
                        textColor: .textSecondary
                    )
                    contentView
                }
                
                rightView
            }
        }
    }
}
