//
//  File.swift
//
//
//  Created by Giang Long Tran on 05.04.2023.
//

import Foundation
import KeyAppBusiness
import KeyAppKitCore

public struct WormholeClaimUserAction: UserAction {
    public enum InternalState: Codable, Equatable {
        case pending(WormholeBundle)
        case processing
        case ready
        case error(UserActionError)
    }

    public var id: String { bundleID }

    public let bundleID: String

    public var status: UserActionStatus {
        switch internalState {
        case .pending:
            return .pending
        case .processing:
            return .processing
        case .ready:
            return .ready
        case let .error(error):
            return .error(error)
        }
    }

    public var internalState: InternalState

    public let createdDate: Date

    public var updatedDate: Date

    /// Ethereum token
    public let token: EthereumToken

    /// Amount in crypto
    public let amountInCrypto: CryptoAmount

    /// Amount in fiat
    public let amountInFiat: CurrencyAmount?

    /// Claim fees information
    public let fees: ClaimFees

    public let compensationDeclineReason: CompensationDeclineReason?

    public init(
        token: EthereumToken,
        bundle: WormholeBundle
    ) {
        bundleID = bundle.bundleId
        internalState = .pending(bundle)

        createdDate = Date()
        updatedDate = createdDate

        self.token = token
        amountInCrypto = bundle.resultAmount.asCryptoAmount
        amountInFiat = bundle.resultAmount.asCurrencyAmount
        fees = bundle.fees
        compensationDeclineReason = bundle.compensationDeclineReason
    }

    /// Extract user action from ``BundleStatus``.
    /// Method is not ready for usage due missing compensationDeclineReason from backend.
    public init(
        bundleStatus: WormholeBundleStatus,
        token: EthereumToken
    ) {
        bundleID = bundleStatus.bundleId

        switch bundleStatus.status {
        case .failed, .expired, .canceled:
            internalState = .error(WormholeClaimUserActionError.claimFailure)
        case .pending, .inProgress:
            internalState = .processing
        case .completed:
            internalState = .ready
        }

        createdDate = Date()
        updatedDate = createdDate

        self.token = token
        amountInCrypto = bundleStatus.resultAmount.asCryptoAmount
        amountInFiat = bundleStatus.resultAmount.asCurrencyAmount
        fees = bundleStatus.fees
        compensationDeclineReason = bundleStatus.compensationDeclineReason
    }

    /// Client side moving to next status.
    /// Only move from processing to ready or error internal state.
    public mutating func moveToNextStatus(nextStatus: WormholeStatus) {
        switch internalState {
        case .processing:
            switch nextStatus {
            case .completed:
                internalState = .ready
            case .pending, .inProgress:
                return
            case .failed, .expired, .canceled:
                internalState = .error(WormholeClaimUserActionError.claimFailure)
            }
        default:
            return
        }
    }
}
