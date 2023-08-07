import Foundation
import KeyAppBusiness
import KeyAppKitCore
import SolanaSwift

struct PendingTransaction {
    enum TransactionStatus {
        case sending
        case confirmed(_ numberOfConfirmed: Int)
        case finalized
        case error(_ error: Swift.Error)
        case confirmationNeeded

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
