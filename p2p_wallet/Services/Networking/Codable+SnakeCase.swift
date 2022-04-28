//
//  Codable+SnakeCase.swift
//  p2p_wallet
//
//  Created by Ivan on 28.04.2022.
//

import Foundation

extension Encodable {
    var snakeCaseEncoded: String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.keyEncodingStrategy = .convertToSnakeCase
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
