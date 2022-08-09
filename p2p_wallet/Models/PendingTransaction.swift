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
            // swiftlint:disable swiftgen_strings
            let string = NSLocalizedString(error ?? "", comment: "")
            // swiftlint:enable swiftgen_strings
            status = .error(string)
        }

        let signature = transactionId

        var value: AnyHashable?
        let amountInFiat: Double?
        let fee: FeeAmount?

        switch rawTransaction {
        case let transaction as ProcessTransaction.SendTransaction:
            let amount = transaction.amount.convertToBalance(decimals: transaction.sender.token.decimals)
            value = TransferInfo(
                source: transaction.sender,
                destination: Wallet(pubkey: transaction.receiver.address, lamports: 0, token: transaction.sender.token),
                authority: authority,
                destinationAuthority: nil,
                rawAmount: amount,
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

            value = SwapInfo(
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
