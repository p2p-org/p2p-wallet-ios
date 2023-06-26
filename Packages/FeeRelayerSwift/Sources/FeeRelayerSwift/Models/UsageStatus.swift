// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

/// A user's usage status for fee relayer service.
public struct UsageStatus: Equatable, Codable {
    public let maxUsage: Int
    public var currentUsage: Int
    public let maxAmount: UInt64
    public var amountUsed: UInt64
    public var reachedLimitLinkCreation: Bool
    
    public init(
        maxUsage: Int,
        currentUsage: Int,
        maxAmount: UInt64,
        amountUsed: UInt64,
        reachedLimitLinkCreation: Bool
    ) {
        self.maxUsage = maxUsage
        self.currentUsage = currentUsage
        self.maxAmount = maxAmount
        self.amountUsed = amountUsed
        self.reachedLimitLinkCreation = reachedLimitLinkCreation
    }
    
    public func isFreeTransactionFeeAvailable(transactionFee: UInt64) -> Bool {
        currentUsage < maxUsage && (amountUsed + transactionFee) <= maxAmount
    }
}
