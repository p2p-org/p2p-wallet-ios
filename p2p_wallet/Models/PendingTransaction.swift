//
//  PendingTransaction.swift
//  p2p_wallet
//
//  Created by Chung Tran on 06/03/2022.
//

import Foundation
import SolanaSwift

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
