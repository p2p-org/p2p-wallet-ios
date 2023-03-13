//
//  File.swift
//
//
//  Created by Giang Long Tran on 12.03.2023.
//

import Foundation
import SolanaPricesAPIs

class MockPricesNetworkManager: PricesNetworkManager {
    var handler: (_ urlString: String) -> Encodable
    
    init(handler: @escaping (_: String) -> Encodable) {
        self.handler = handler
    }

    func get(urlString: String) async throws -> Data {
        try JSONEncoder().encode(handler(urlString))
    }
}
