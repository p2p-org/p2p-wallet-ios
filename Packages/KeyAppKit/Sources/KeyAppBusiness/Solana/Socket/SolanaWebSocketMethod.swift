//
//  File.swift
//
//
//  Created by Giang Long Tran on 04.05.2023.
//

import Foundation
import KeyAppKitCore
import SolanaSwift

/// Class for generating rpc request to socket.
///
/// Full methods list: https://docs.solana.com/api/websocket
class SolanaWebSocketMethods {
    func accountSubscribe(
        account: String,
        commitment: Commitment = "finalized",
        encoding: String = "base64"
    ) -> [String: Any] {
        [
            "jsonrpc": "2.0",
            "id": UUID().uuidString,
            "method": "accountSubscribe",
            "params": [
                account,
                ["commitment": commitment, "encoding": encoding],
            ] as [Any],
        ]
    }

    func programSubscribe(
        program: String,
        commitment: Commitment = "finalized",
        encoding: String = "base64",
        filters: [Any]? = nil
    ) -> [String: Any] {
        [
            "jsonrpc": "2.0",
            "id": UUID().uuidString,
            "method": "programSubscribe",
            "params": [
                program,
                ["commitment": commitment, "encoding": encoding, "filters": filters],
            ] as [Any],
        ]
    }
}
