//
//  File.swift
//
//
//  Created by Giang Long Tran on 21.03.2023.
//

import Foundation
import KeyAppKitCore

public enum WormholeToken: Codable, Hashable {
    case ethereum(String?)
    case solana(String?)

    public init(chain: String, token: String?) throws {
        switch chain {
        case "Ethereum":
            self = .ethereum(token)
        case "Solana":
            self = .solana(token)
        default:
            throw CodingError.invalidValue
        }
    }
}
