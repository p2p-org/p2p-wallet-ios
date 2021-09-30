//
//  ProcessTransaction.swift
//  p2p_wallet
//
//  Created by Chung Tran on 02/06/2021.
//

import Foundation
import RxSwift

protocol ProcessTransactionAPIClient {
    func getReimbursedAmountForClosingToken() -> Single<Double>
}
extension SolanaSDK: ProcessTransactionAPIClient {
    func getReimbursedAmountForClosingToken() -> Single<Double> {
        getCreatingTokenAccountFee().map {$0.convertToBalance(decimals: 9)}
    }
}

struct ProcessTransaction {
    enum NavigatableScene {
        case showExplorer(transactionID: String)
        case done
        case cancel
    }
    
    enum TransactionType {
        case send(from: Wallet, to: String, lamport: SolanaSDK.Lamports, feeInLamports: SolanaSDK.Lamports)
        case orcaSwap(from: Wallet, to: Wallet, inputAmount: SolanaSDK.Lamports, estimatedAmount: SolanaSDK.Lamports, fees: [PayingFee])
        case swap(provider: SwapProviderType, from: Wallet, to: Wallet, inputAmount: Double, estimatedAmount: Double, fees: [PayingFee], slippage: Double, isSimulation: Bool)
        case closeAccount(Wallet)
    }
}
