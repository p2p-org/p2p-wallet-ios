//
//  File.swift
//
//
//  Created by Giang Long Tran on 11.04.2023.
//

import Foundation

public struct UserActionError: Error, Equatable, Codable {
    public let domain: String
    public let code: Int
    public let reason: String

    public init(domain: String, code: Int, reason: String) {
        self.domain = domain
        self.code = code
        self.reason = reason
    }
}

/// Network error
public extension UserActionError {
    private static let networkDomain: String = "Network"

    static let networkFailure: UserActionError = .init(
        domain: networkDomain,
        code: 1,
        reason: "Internet connection is broken"
    )
}

public extension UserActionError {
    private static let feeRelayDomain: String = "FeeRelay"

    static let topUpFailure: UserActionError = .init(
        domain: feeRelayDomain,
        code: 1,
        reason: "Top up failure"
    )

    static let signingFailure: UserActionError = .init(
        domain: "Internal",
        code: 2,
        reason: "Signing failure"
    )
}
