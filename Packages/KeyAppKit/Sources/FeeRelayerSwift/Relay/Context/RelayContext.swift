// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

public struct RelayContext: Hashable, Codable {
    public let minimumTokenAccountBalance: UInt64
    public let minimumRelayAccountBalance: UInt64
    public let feePayerAddress: PublicKey
    public let lamportsPerSignature: UInt64
    public let relayAccountStatus: RelayAccountStatus
    public var usageStatus: UsageStatus
    
    public init(
        minimumTokenAccountBalance: UInt64,
        minimumRelayAccountBalance: UInt64,
        feePayerAddress: PublicKey,
        lamportsPerSignature: UInt64,
        relayAccountStatus: RelayAccountStatus,
        usageStatus: UsageStatus
    ) {
        self.minimumTokenAccountBalance = minimumTokenAccountBalance
        self.minimumRelayAccountBalance = minimumRelayAccountBalance
        self.feePayerAddress = feePayerAddress
        self.lamportsPerSignature = lamportsPerSignature
        self.relayAccountStatus = relayAccountStatus
        self.usageStatus = usageStatus
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(minimumTokenAccountBalance)
        hasher.combine(minimumRelayAccountBalance)
        hasher.combine(feePayerAddress)
        hasher.combine(lamportsPerSignature)
    }
}
