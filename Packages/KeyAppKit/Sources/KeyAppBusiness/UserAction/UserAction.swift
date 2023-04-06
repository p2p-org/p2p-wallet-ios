//
//  File.swift
//
//
//  Created by Giang Long Tran on 30.03.2023.
//

import Foundation

public enum UserActionStatus: Codable {
    /// Action is waiting to perform.
    case pending

    /// Action is in progress.
    case processing

    /// Action is finished.
    case ready

    /// Action occurs error.
    case error(UserActionError)
}

public protocol UserAction: Codable {
    /// Unique internal id to track inside application.
    var id: String { get set }

    var trackingKey: Set<String> { get }

    /// Abstract status.
    var status: UserActionStatus { get }

    var createdDate: Date { get }

    var updatedDate: Date { get set }
}

public struct UserActionError: Error, Equatable, Codable {
    public let domain: String
    public let code: Int
    public let reason: String

    public init(domain: String, code: Int, reason: String) {
        self.domain = domain
        self.code = code
        self.reason = reason
    }

    public static let networkDomain: String = "Network"

    public static let networkFailure: UserActionError = .init(
        domain: networkDomain,
        code: 1,
        reason: "Internet connection is broken"
    )

    public static let feeRelayDomain: String = "FeeRelay"

    public static let topUpFailure: UserActionError = .init(
        domain: feeRelayDomain,
        code: 1,
        reason: "Top up failure"
    )

    public static let signingFailure: UserActionError = .init(
        domain: "Internal",
        code: 1,
        reason: "Signing failure"
    )
}
