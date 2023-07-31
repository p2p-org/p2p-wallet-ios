// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

extension SwapTransactionBuilderImpl {
    func checkSigners(
        ownerAccount: KeyPair,
        env: inout SwapTransactionBuilderOutput
    ) {
        env.signers.append(ownerAccount)
        if let sourceWSOLNewAccount = env.sourceWSOLNewAccount { env.signers.append(sourceWSOLNewAccount) }
        if let destinationNewAccount = env.destinationNewAccount { env.signers.append(destinationNewAccount) }
    }
}

