// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

extension SolanaAccountStorage {
    var pubkey: PublicKey {
        get throws {
            try account?.publicKey ?! FeeRelayerError.unauthorized
        }
    }
    
    var signer: KeyPair {
        get throws {
            try account ?! FeeRelayerError.unauthorized
        }
    }
}
