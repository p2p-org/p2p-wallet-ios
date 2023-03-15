//
//  File.swift
//
//
//  Created by Giang Long Tran on 14.03.2023.
//

import Foundation

/// A data structure for handling bridging ethereum network to solana network.
public struct WormholeBundle: Codable, Hashable {
    public let bundleId: String
    
    public let userWallet: String
    
    public let recipient: String
    
    public let token: String
    
    public let withCompensation: WithCompensation
    
    public let expiresAt: String
    
    public var expiresAtDate: Date? {
        Self.expiresAtFormatter.date(from: self.expiresAt)
    }
    
    public let transactions: [String]
    
    public var signatures: [String]?
    
    public let fees: EthereumFees

    public enum CodingKeys: String, CodingKey {
        case bundleId = "bundle_id"
        case userWallet = "user_wallet"
        case recipient
        case token
        case withCompensation = "with_compensations"
        case expiresAt = "expires_at"
        case transactions
        case signatures
        case fees
    }
    
    /// Date formatter for expiresAt
    /// Example: 2023-03-01T16:40:54.079434Z
    private static let expiresAtFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"

        return dateFormatter
    }()
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.bundleId = try container.decode(String.self, forKey: .bundleId)
        self.userWallet = try container.decode(String.self, forKey: .userWallet)
        self.recipient = try container.decode(String.self, forKey: .recipient)
        self.token = try container.decode(String.self, forKey: .token)
        self.expiresAt = try container.decode(String.self, forKey: .expiresAt)
        self.transactions = try container.decode([String].self, forKey: .transactions)
        self.signatures = try container.decodeIfPresent([String].self, forKey: .signatures)
        self.fees = try container.decode(EthereumFees.self, forKey: .fees)
        
        let compensationValue = try? container.decode(String.self, forKey: .withCompensation)
        if compensationValue == "yes" {
            self.withCompensation = .yes
        } else {
            self.withCompensation = try container.decode(WithCompensation.self, forKey: .withCompensation)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.bundleId, forKey: .bundleId)
        try container.encode(self.userWallet, forKey: .userWallet)
        try container.encode(self.recipient, forKey: .recipient)
        try container.encode(self.token, forKey: .token)
        try container.encode(self.expiresAt, forKey: .expiresAt)
        try container.encode(self.transactions, forKey: .transactions)
        try container.encodeIfPresent(self.signatures, forKey: .signatures)
        try container.encode(self.fees, forKey: .fees)
        
        switch self.withCompensation {
        case .yes:
            try container.encode("yes", forKey: .withCompensation)
        case .no:
            try container.encode(self.withCompensation, forKey: .withCompensation)
        }
    }
}

public enum WithCompensation: Codable, Hashable {
    case yes
    
    case no(CompensationReason)
    
    enum CodingKeys: CodingKey {
        case yes
        case no
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var allKeys = ArraySlice(container.allKeys)
        guard let onlyKey = allKeys.popFirst(), allKeys.isEmpty else {
            throw DecodingError.typeMismatch(WithCompensation.self, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Invalid number of keys found, expected one.", underlyingError: nil))
        }
        switch onlyKey {
        case .no:
            let reason = try container.decode(CompensationReason.self, forKey: .no)
            self = WithCompensation.no(reason)
        default:
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unexpected key"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .no(let reason):
            try container.encode(reason, forKey: .no)
        default:
            throw DecodingError.dataCorrupted(.init(codingPath: encoder.codingPath, debugDescription: "The value 'yes' can not ve encoded"))
        }
    }
}

public enum CompensationReason: String, Codable, Hashable {
    case gasPriceTooHigh = "gas_price_too_high"
    case amountTooLow = "amount_too_low"
    case limitExceed = "limit_exceed"
}

