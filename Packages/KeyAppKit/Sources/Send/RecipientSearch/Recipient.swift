// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

public struct Recipient: Hashable, Codable {
    public struct Attribute: OptionSet, Hashable, Codable {
        public let rawValue: Int

        /// Account has funds (SOL) or has SPL token accounts (PDAs)
        @available(*, deprecated, message: "Will be removed")
        public static let funds = Attribute(rawValue: 1 << 0)

        /// The address is PDA
        public static let pda = Attribute(rawValue: 1 << 1)

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }

    public enum Category: Hashable, Codable {
        case username(name: String, domain: String)

        case solanaAddress
        case solanaTokenAddress(walletAddress: PublicKey, token: Token)

        case bitcoinAddress

        public var isDirectSPLTokenAddress: Bool {
            switch self {
            case .solanaTokenAddress:
                return true
            default:
                return false
            }
        }
    }

    public init(address: String, category: Category, attributes: Attribute, createdData: Date? = nil) {
        self.address = address
        self.category = category
        self.attributes = attributes
        self.createdData = createdData
    }

    public func copy(createdData: Date? = nil) -> Self {
        .init(
            address: address,
            category: category,
            attributes: attributes,
            createdData: createdData ?? self.createdData
        )
    }

    public let address: String
    public let category: Category

    public let attributes: Attribute
    public let createdData: Date?
}

extension Recipient: Identifiable {
    public var id: String { "\(address)-\(attributes)-\(category)" }
}
