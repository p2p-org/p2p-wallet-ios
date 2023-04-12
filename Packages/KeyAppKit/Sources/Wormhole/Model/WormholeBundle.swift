//
//  File.swift
//
//
//  Created by Giang Long Tran on 14.03.2023.
//

import BigInt
import Foundation
import KeyAppKitCore
import Web3

/// A data structure for handling bridging ethereum network to solana network.
public struct WormholeBundle: Codable, Hashable, Equatable {
    public let bundleId: String

    public let userWallet: String

    public let recipient: String

    public let resultAmount: TokenAmount

    public let compensationDeclineReason: CompensationDeclineReason?

    public let expiresAt: Int

    public var expiresAtDate: Date {
        Date(timeIntervalSince1970: TimeInterval(expiresAt))
    }

    public let transactions: [String]

    public var signatures: [EthereumSignature]?

    public let fees: ClaimFees

    public enum CodingKeys: String, CodingKey {
        case bundleId = "bundle_id"
        case userWallet = "user_wallet"
        case recipient
        case resultAmount = "result_amount"
        case compensationDeclineReason = "compensation_decline_reason"
        case expiresAt = "expires_at"
        case transactions
        case signatures
        case fees
    }
}

public extension WormholeBundle {
    mutating func signBundle(with keyPair: EthereumKeyPair) throws {
        // Sign transactions
        signatures = try transactions.map { transaction -> EthereumSignature in
            var transactionBytes = transaction.hexToBytes()
            if transactionBytes[0] == EthereumTransaction.TransactionType.eip1559.byte! {
                transactionBytes.remove(at: 0)
            }

            let rlpItem: RLPItem = try RLPDecoder().decode(transactionBytes)

            let transaction = try EthereumTransaction(rlp: rlpItem)
            let signedTransaction = try keyPair.sign(transaction: transaction, chainID: 1)

            return EthereumSignature(
                r: signedTransaction.r.hex(),
                s: signedTransaction.s.hex(),
                v: try UInt64(signedTransaction.v.quantity)
            )
        }
    }
}

private extension EthereumTransaction.TransactionType {
    var byte: UInt? {
        switch self {
        case .eip1559:
            return 0x02
        default:
            return nil
        }
    }
}

public enum CompensationDeclineReason: String, Codable, Hashable {
    case gasPriceTooHigh = "gas_price_too_high"
    case amountTooLow = "amount_too_low"
    case limitExceed = "limit_exceed"
}

public struct EthereumSignature: Codable, Hashable {
    let r: String
    let s: String
    let v: UInt64
}
