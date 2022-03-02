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
            static let maxConfirmed = 20
            
            case sending
            case confirmed(_ numberOfConfirmed: Int)
            case finalized
            
            var progress: Float {
                switch self {
                case .sending:
                    return 0
                case .confirmed(var numberOfConfirmed):
                    // treat all number of confirmed as unfinalized
                    if numberOfConfirmed >= 20 {
                        numberOfConfirmed = 19
                    }
                    // return
                    return Float(numberOfConfirmed) / Float(Self.maxConfirmed)
                case .finalized:
                    return 1
                }
            }
        }
        
        var transactionId: String?
        var status: TransactionStatus
    }
}
