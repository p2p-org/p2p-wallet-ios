//
//  PendingTransaction.swift
//  p2p_wallet
//
//  Created by Chung Tran on 06/03/2022.
//

import Foundation
import RxSwift

struct PendingTransaction {
    enum TransactionStatus {
        static let maxConfirmed = 31
        
        case sending
        case confirmed(_ numberOfConfirmed: Int)
        case finalized
        case error(_ error: Swift.Error)
        
        var numberOfConfirmations: Int? {
            switch self {
            case .confirmed(let numberOfConfirmations):
                return numberOfConfirmations
            default:
                return nil
            }
        }
        
        var isProcessing: Bool {
            switch self {
            case .sending, .confirmed:
                return true
            default:
                return false
            }
        }
        
        var progress: Float {
            switch self {
            case .sending:
                return 0
            case .confirmed(var numberOfConfirmed):
                // treat all number of confirmed as unfinalized
                if numberOfConfirmed >= Self.maxConfirmed {
                    numberOfConfirmed = Self.maxConfirmed - 1
                }
                // return
                return Float(numberOfConfirmed) / Float(Self.maxConfirmed)
            case .finalized, .error:
                return 1
            }
        }
        
        var error: Swift.Error? {
            switch self {
            case .error(let error):
                return error
            default:
                return nil
            }
        }
        
        public var rawValue: String {
            switch self {
            case .sending:
                return "sending"
            case .confirmed:
                return "processing"
            case .finalized:
                return "finalized"
            case .error:
                return "error"
            }
        }
    }
    
    var transactionId: String?
    let sentAt: Date
    var writtenToRepository: Bool = false
    let rawTransaction: RawTransactionType
    var status: TransactionStatus
    var slot: UInt64 = 0
}

extension PendingTransaction {
    func parse(pricesService: PricesServiceType, authority: String? = nil) -> SolanaSDK.ParsedTransaction? {
        // status
        let status: SolanaSDK.ParsedTransaction.Status
        
        switch self.status {
        case .sending:
            status = .requesting
        case .confirmed:
            status = .processing(percent: 0)
        case .finalized:
            status = .confirmed
        case .error(let error):
            status = .error(error.readableDescription)
        }
        
        let signature = transactionId
        
        var value: AnyHashable?
        let amountInFiat: Double?
        let fee: UInt64?
        
        switch rawTransaction {
        case let transaction as ProcessTransaction.SendTransaction:
            let amount = transaction.amount.convertToBalance(decimals: transaction.sender.token.decimals)
            value = SolanaSDK.TransferTransaction(
                source: transaction.sender,
                destination: Wallet(pubkey: transaction.receiver.address, lamports: 0, token: transaction.sender.token),
                authority: authority,
                destinationAuthority: nil,
                amount: amount,
                myAccount: transaction.sender.pubkey
            )
            amountInFiat = amount * pricesService.currentPrice(for: transaction.sender.token.symbol)?.value
            fee = transaction.feeInSOL
        case let transaction as ProcessTransaction.OrcaSwapTransaction:
            value = SolanaSDK.SwapTransaction(
                source: transaction.sourceWallet,
                sourceAmount: transaction.amount,
                destination: transaction.destinationWallet,
                destinationAmount: transaction.estimatedAmount,
                myAccountSymbol: nil
            )
            amountInFiat = transaction.amount * pricesService.currentPrice(for: transaction.sourceWallet.token.symbol)?.value
            fee = transaction.fees.networkFees?.total
        default:
            return nil
        }
        
        return .init(status: status, signature: signature, value: value, amountInFiat: amountInFiat, slot: self.slot, blockTime: sentAt, fee: fee, blockhash: nil)
    }
}
