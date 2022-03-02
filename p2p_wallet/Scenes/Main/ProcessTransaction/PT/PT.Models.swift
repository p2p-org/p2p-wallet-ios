//
//  PT.Models.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/12/2021.
//

import Foundation
import RxSwift

// MARK: - APIClient
protocol ProcessTransactionAPIClient {
    func getReimbursedAmountForClosingToken() -> Single<Double>
}
extension SolanaSDK: ProcessTransactionAPIClient {
    func getReimbursedAmountForClosingToken() -> Single<Double> {
        getCreatingTokenAccountFee().map {$0.convertToBalance(decimals: 9)}
    }
}

// MARK: - Transaction type
protocol ProcessingTransactionType {}

extension ProcessingTransactionType {
    var isSwap: Bool {
        self is PT.OrcaSwapTransaction || self is PT.SwapTransaction
    }
}

extension PT {
    struct SwapTransaction: ProcessingTransactionType {
        
    }
    
    struct OrcaSwapTransaction: ProcessingTransactionType {
        
    }
    
    struct CloseTransaction: ProcessingTransactionType {
        
    }
    
    struct SendTransaction: ProcessingTransactionType {
        let sendService: SendServiceType
        let network: SendToken.Network
        let sender: Wallet
        let receiver: SendToken.Recipient
        let amount: SolanaSDK.Lamports
        let payingFeeWallet: Wallet?
        let isSimulation: Bool
    }
}

// MARK: - Transaction status
extension PT {
    struct TransactionInfo {
        enum TransactionStatus {
            case sending
            case confirmed(_ numberOfConfirmed: Int)
            case finalized
        }
        
        let transactionId: String?
        let status: TransactionStatus
    }
}
