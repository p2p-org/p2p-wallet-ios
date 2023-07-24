//
//  PendingTransaction.swift
//  p2p_wallet
//
//  Created by Chung Tran on 06/03/2022.
//

import Foundation
import KeyAppBusiness
import KeyAppKitCore
import SolanaSwift
import TransactionParser

struct PendingTransaction {
    enum TransactionStatus {
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

        var isSent: Bool {
            switch self {
            case .sending:
                return false
            default:
                return true
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

        var error: Swift.Error? {
            switch self {
            case let .error(error):
                return error
            default:
                return nil
            }
        }
    }

    let trxIndex: Int
    var transactionId: String?
    let sentAt: Date
    let rawTransaction: RawTransactionType
    var status: TransactionStatus
    var slot: UInt64 = 0

    var isConfirmedOrError: Bool {
        status.error != nil || status.isFinalized || (status.numberOfConfirmations ?? 0) > 0
    }
}
