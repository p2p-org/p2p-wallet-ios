//
//  PendingTransaction.swift
//  p2p_wallet
//
//  Created by Chung Tran on 06/03/2022.
//

import Foundation
import RxSwift
import SolanaSwift
import TransactionParser

struct PendingTransaction {
    enum TransactionStatus {
        static let maxConfirmed = 31

        case sending
        case confirmed(_ numberOfConfirmed: Int)
        case finalized
        case error(_ error: Swift.Error)

        var numberOfConfirmations: Int? {
            switch self {
            case let .confirmed(numberOfConfirmations):
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
            case var .confirmed(numberOfConfirmed):
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
            case let .error(error):
                return error
            default:
                return nil
            }
        }

        public var rawValue: String {
            switch self {
            case .sending:
                return "sending"
            case let .confirmed(value):
                return "processing(\(value))"
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
    func parse(pricesService: PricesServiceType, authority: String? = nil) -> ParsedTransaction? {
        // status
        let status: ParsedTransaction.Status

        switch self.status {
        case .sending:
            status = .requesting
        case .confirmed:
            status = .processing(percent: 0)
        case .finalized:
            status = .confirmed
        case let .error(error):
            status = .error(error.readableDescription)
        }

        let signature = transactionId

        var value: AnyHashable?
        let amountInFiat: Double?
        let fee: FeeAmount?

        switch rawTransaction {
        case let transaction as ProcessTransaction.SendTransaction:
            let amount = transaction.amount.convertToBalance(decimals: transaction.sender.token.decimals)
            value = TransferTransaction(
                source: transaction.sender,
                destination: Wallet(pubkey: transaction.receiver.address, lamports: 0, token: transaction.sender.token),
                authority: authority,
                destinationAuthority: nil,
                amount: amount,
                account: transaction.sender.pubkey
            )
            amountInFiat = amount * pricesService.currentPrice(for: transaction.sender.token.symbol)?.value
            fee = transaction.feeInToken
        case let transaction as ProcessTransaction.SwapTransaction:
            var destinationWallet = transaction.destinationWallet
            if let authority = try? PublicKey(string: authority),
               let mintAddress = try? PublicKey(string: destinationWallet.mintAddress)
            {
                destinationWallet.pubkey = try? PublicKey.associatedTokenAddress(
                    walletAddress: authority,
                    tokenMintAddress: mintAddress
                ).base58EncodedString
            }

            value = SwapTransaction(
                source: transaction.sourceWallet,
                sourceAmount: transaction.amount,
                destination: destinationWallet,
                destinationAmount: transaction.estimatedAmount,
                accountSymbol: nil
            )
            amountInFiat = transaction.amount * pricesService.currentPrice(for: transaction.sourceWallet.token.symbol)?
                .value
            fee = transaction.fees.networkFees
        default:
            return nil
        }

        return .init(
            status: status,
            signature: signature,
            info: value,
            amountInFiat: amountInFiat,
            slot: slot,
            blockTime: sentAt,
            fee: fee,
            blockhash: nil
        )
    }
}
