//
//  TransactionStatus+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/08/2022.
//

import Foundation
import SolanaSwift
import TransactionParser

extension TransactionStatus {
    static let maxConfirmed: UInt64 = 31

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
        case var .confirmed(numberOfConfirmed, _):
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
    
    var isFinalized: Bool {
        switch self {
        case .finalized:
            return true
        default:
            return false
        }
    }

    var error: String? {
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
        case let .confirmed(value, _):
            return "processing(\(value))"
        case .finalized:
            return "finalized"
        case .error:
            return "error"
        }
    }
}
