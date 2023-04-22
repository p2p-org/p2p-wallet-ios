//
//  PendingTransaction.swift
//  p2p_wallet
//
//  Created by Chung Tran on 06/03/2022.
//

import Foundation
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
        
        var isFinalized: Bool {
            switch self {
            case .finalized:
                return true
            default:
                return false
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

    let trxIndex: Int
    var transactionId: String?
    let sentAt: Date
    var writtenToRepository: Bool = false
    let rawTransaction: RawTransactionType
    var status: TransactionStatus
    var slot: UInt64 = 0
    
    var isConfirmedOrError: Bool {
        status.error != nil || status.isFinalized || (status.numberOfConfirmations ?? 0) > 0
    }
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
        case let transaction as SendTransaction:
            value = TransferInfo(
                source: transaction.walletToken,
                destination: Wallet(pubkey: transaction.recipient.address, lamports: 0, token: transaction.walletToken.token),
                authority: authority,
                destinationAuthority: nil,
                rawAmount: transaction.amount,
                account: transaction.walletToken.pubkey
            )
            amountInFiat = transaction.amountInFiat
            fee = transaction.feeAmount
        case let transaction as SwapRawTransactionType:
            var destinationWallet = transaction.destinationWallet
            if let authority = try? PublicKey(string: authority),
               let mintAddress = try? PublicKey(string: destinationWallet.mintAddress)
            {
                destinationWallet.pubkey = try? PublicKey.associatedTokenAddress(
                    walletAddress: authority,
                    tokenMintAddress: mintAddress
                ).base58EncodedString
            }

            value = SwapInfo(
                source: transaction.sourceWallet,
                sourceAmount: transaction.fromAmount,
                destination: destinationWallet,
                destinationAmount: transaction.toAmount,
                accountSymbol: nil
            )
            amountInFiat = transaction.fromAmount * pricesService.currentPrice(mint: transaction.sourceWallet.token.address)?
                .value
            fee = transaction.feeAmount
        case let transaction as ClaimSentViaLinkTransaction:
            value = TransferInfo(
                source: Wallet(
                    pubkey: transaction.claimableTokenInfo.account,
                    token: transaction.token
                ) ,
                destination: transaction.destinationWallet,
                authority: nil,
                destinationAuthority: nil,
                rawAmount: transaction.tokenAmount,
                account: transaction.claimableTokenInfo.keypair.publicKey.base58EncodedString
            )
            amountInFiat = transaction.amountInFiat
            fee = transaction.feeAmount
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
