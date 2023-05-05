// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

// MARK: - Quote
public struct Route: Codable, Equatable {
    public let inAmount, outAmount: String
    public let priceImpactPct: Decimal
    public let marketInfos: [MarketInfo]
    public let amount: String
    public let slippageBps: Int
    public let otherAmountThreshold, swapMode: String
    public let fees: Fees?
    public let keyapp: KeyAppInfo?

    public init(
        inAmount: String,
        outAmount: String,
        priceImpactPct: Decimal,
        marketInfos: [MarketInfo],
        amount: String,
        slippageBps: Int,
        otherAmountThreshold: String,
        swapMode: String,
        fees: Fees?,
        keyapp: KeyAppInfo?
    ) {
        self.inAmount = inAmount
        self.outAmount = outAmount
        self.priceImpactPct = priceImpactPct
        self.marketInfos = marketInfos
        self.amount = amount
        self.slippageBps = slippageBps
        self.otherAmountThreshold = otherAmountThreshold
        self.swapMode = swapMode
        self.fees = fees
        self.keyapp = keyapp
    }
}

// MARK: - MarketInfo

public struct MarketInfo: Codable, Equatable {
    public let id, label: String
    public let inputMint, outputMint: String
    public let notEnoughLiquidity: Bool
    public let inAmount, outAmount: String
    public let priceImpactPct: Decimal
    public let lpFee, platformFee: PlatformFee

    public init(
        id: String,
        label: String,
        inputMint: String,
        outputMint: String,
        notEnoughLiquidity: Bool,
        inAmount: String,
        outAmount: String,
        priceImpactPct: Decimal,
        lpFee: PlatformFee,
        platformFee: PlatformFee
    ) {
        self.id = id
        self.label = label
        self.inputMint = inputMint
        self.outputMint = outputMint
        self.notEnoughLiquidity = notEnoughLiquidity
        self.inAmount = inAmount
        self.outAmount = outAmount
        self.priceImpactPct = priceImpactPct
        self.lpFee = lpFee
        self.platformFee = platformFee
    }
}


// MARK: - PlatformFee

public struct PlatformFee: Codable, Equatable {
    public let amount: String
    public let mint: String
    public let pct: Decimal

    public init(amount: String, mint: String, pct: Decimal) {
        self.amount = amount
        self.mint = mint
        self.pct = pct
    }
}

// MARK: - Fees

public struct Fees: Codable, Equatable {
    public let signatureFee: UInt64
    public let openOrdersDeposits: [UInt64]
    public let ataDeposits: [UInt64]
    public let totalFeeAndDeposits: UInt64
    public let minimumSOLForTransaction: UInt64
}

// MARK: - KeyApp

public struct KeyAppInfo: Codable, Equatable {
    public let fee: String
    public let refundableFee: String
    public let _hash: String
}
