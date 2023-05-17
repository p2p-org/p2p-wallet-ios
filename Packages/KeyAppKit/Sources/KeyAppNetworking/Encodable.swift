//
//  Encodable.swift
//  p2p_wallet
//
//  Created by Ivan on 28.04.2022.
//

import Foundation

public extension Encodable {
    /// Snake case Encoded string for request as a json string
    var snakeCaseEncoded: String? {
        encoded(strategy: .convertToSnakeCase)
    }
    
    /// Encoded string for request as a json string
    var encoded: String? {
        encoded(strategy: .useDefaultKeys)
    }
    
    private func encoded(strategy: JSONEncoder.KeyEncodingStrategy) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.keyEncodingStrategy = strategy
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
