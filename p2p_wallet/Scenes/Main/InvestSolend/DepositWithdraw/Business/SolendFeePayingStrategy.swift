// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import FeeRelayerSwift
import Foundation
import OrcaSwapSwift
import Resolver
import SolanaSwift
import Solend

struct SolendFeePaying: Equatable {
    let symbol: String
    let decimals: UInt8
    
    let fee: SolanaSwift.FeeAmount
    let feePayer: FeeRelayerSwift.TokenAccount
}

enum SolendFeePayingStrategyError: Error {
    case invalidNativeWallet
}

protocol SolendFeePayingStrategy {
    func calculate(amount: Lamports, symbol: String, mintAddress: String) async throws -> SolendFeePaying
}
