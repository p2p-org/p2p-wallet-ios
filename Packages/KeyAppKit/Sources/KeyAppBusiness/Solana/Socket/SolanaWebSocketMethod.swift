// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import KeyAppKitCore
import SolanaSwift

/// Class for generating rpc request to socket.
///
/// Full methods list: https://docs.solana.com/api/websocket
final class SolanaWebSocketMethods {
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
