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
    public var id: String

    public var status: UserActionStatus

    public let createdDate: Date

    public var updatedDate: Date

    /// Ethereum token
    public let token: EthereumToken

    /// Amount in crypto
    public let amountInCrypto: CryptoAmount

    /// Amount in fiat
    public let amountInFiat: CurrencyAmount?

    public enum BundleValue: Codable, Equatable {
        case bundle(WormholeBundle)
        case bundleStatus(WormholeBundleStatus)
    }

    /// Wormhole bundle
    public var bundle: BundleValue

    public init(
        token: EthereumToken,
        amountInCrypto: CryptoAmount,
        amountInFiat: CurrencyAmount?,
        bundle: WormholeBundle
    ) {
        id = UUID().uuidString
        status = .pending
        createdDate = Date()
        updatedDate = createdDate

        self.token = token
        self.amountInCrypto = amountInCrypto
        self.amountInFiat = amountInFiat
        self.bundle = .bundle(bundle)
    }

    public init(
        bundleStatus: WormholeBundleStatus,
        token: EthereumToken
    ) {
        id = UUID().uuidString

        switch bundleStatus.status {
        case .failed:
            status = .error(.init(domain: "WormholeClaimUserActionConsumer", code: 3, reason: "Claim failure"))
        case .pending:
            status = .pending
        case .expired:
            status = .error(.init(domain: "WormholeClaimUserActionConsumer", code: 3, reason: "Claim is expired"))
        case .canceled:
            status = .error(.init(domain: "WormholeClaimUserActionConsumer", code: 3, reason: "Claim was canceled"))
        case .inProgress:
            status = .processing
        case .completed:
            status = .ready 
        }

        createdDate = Date()
        updatedDate = createdDate

        self.token = token
        amountInCrypto = bundleStatus.resultAmount.asCryptoAmount
        amountInFiat = bundleStatus.resultAmount.asCurrencyAmount
        bundle = .bundleStatus(bundleStatus)
    }
}

extension WormholeClaimUserAction {
    var bundleID: String {
        switch bundle {
        case let .bundle(bundle):
            return bundle.bundleId
        case let .bundleStatus(bundleStatus):
            return bundleStatus.bundleId
        }
    }
}

public extension WormholeClaimUserAction.BundleValue {
    var bundleID: String {
        switch self {
        case let .bundle(bundle):
            return bundle.bundleId
        case let .bundleStatus(bundleStatus):
            return bundleStatus.bundleId
        }
    }

    var resultAmount: TokenAmount {
        switch self {
        case let .bundle(bundle):
            return bundle.resultAmount
        case let .bundleStatus(bundleStatus):
            return bundleStatus.resultAmount
        }
    }

    var compensationDeclineReason: CompensationDeclineReason? {
        switch self {
        case let .bundle(bundle):
            return bundle.compensationDeclineReason
        case .bundleStatus:
            return nil
        }
    }

    var fees: ClaimFees? {
        switch self {
        case let .bundle(bundle):
            return bundle.fees
        case let .bundleStatus(bundleStatus):
            return bundleStatus.fees
        }
    }
}
