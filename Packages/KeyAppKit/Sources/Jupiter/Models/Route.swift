import Foundation

// MARK: - Quote

public struct Route: Codable, Equatable {
    // MARK: - Properties

    public let inAmount, outAmount: String
    public let priceImpactPct: Decimal
    public let marketInfos: [MarketInfo]
    public let amount: String
    public let slippageBps: Int
    public let otherAmountThreshold, swapMode: String
    public let fees: Fees?
    public let keyapp: KeyAppInfo?

    // MARK: - Additional properties (non Codable)

    public let _receiveAt = Date()

    // MARK: - Initializer

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

    // MARK: - Custom Encoding

    // Custom encoding ensures that no additional properties (_receivedAt)\
    // will be included when sending request
    // If any property is missing or unexpectedly added, We got server error 500:
    // Integrity of the route has been compromised

    private enum CodingKeys: String, CodingKey {
        case inAmount, outAmount
        case priceImpactPct
        case marketInfos
        case amount
        case slippageBps
        case otherAmountThreshold, swapMode
        case fees
        case keyapp
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        inAmount = try container.decode(String.self, forKey: .inAmount)
        outAmount = try container.decode(String.self, forKey: .outAmount)
        priceImpactPct = try container.decode(Decimal.self, forKey: .priceImpactPct)
        marketInfos = try container.decode([MarketInfo].self, forKey: .marketInfos)
        amount = try container.decode(String.self, forKey: .amount)
        slippageBps = try container.decode(Int.self, forKey: .slippageBps)
        otherAmountThreshold = try container.decode(String.self, forKey: .otherAmountThreshold)
        swapMode = try container.decode(String.self, forKey: .swapMode)
        fees = try container.decodeIfPresent(Fees.self, forKey: .fees)
        keyapp = try container.decodeIfPresent(KeyAppInfo.self, forKey: .keyapp)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(inAmount, forKey: .inAmount)
        try container.encode(outAmount, forKey: .outAmount)
        try container.encode(priceImpactPct, forKey: .priceImpactPct)
        try container.encode(marketInfos, forKey: .marketInfos)
        try container.encode(amount, forKey: .amount)
        try container.encode(slippageBps, forKey: .slippageBps)
        try container.encode(otherAmountThreshold, forKey: .otherAmountThreshold)
        try container.encode(swapMode, forKey: .swapMode)
        try container.encodeIfPresent(fees, forKey: .fees)
        try container.encodeIfPresent(keyapp, forKey: .keyapp)
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
