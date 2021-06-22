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
        case swap(from: Wallet, to: Wallet, inputAmount: SolanaSDK.Lamports, estimatedAmount: SolanaSDK.Lamports, fee: SolanaSDK.Lamports)
        case closeAccount(Wallet)
    }
    enum TransactionStatus: Equatable {
        static func == (lhs: ProcessTransaction.TransactionStatus, rhs: ProcessTransaction.TransactionStatus) -> Bool {
            switch (lhs, rhs) {
            case (.processing, .processing), (.confirmed, .confirmed):
                return true
            case (.error(let error1), .error(let error2)):
                return error1.localizedDescription == error2.localizedDescription
            default:
                return false
            }
        }
        
        case processing // with or without transaction id
        case confirmed
        case error(Error)
        
        func getError() -> Error? {
            var error: Error?
            switch self {
            case .error(let err):
                error = err
            default:
                break
            }
            return error
        }
        
        var rawValue: String {
            switch self {
            case .processing:
                return "processing"
            case .confirmed:
                return "confirmed"
            case .error:
                return "error"
            }
        }
    }
}
