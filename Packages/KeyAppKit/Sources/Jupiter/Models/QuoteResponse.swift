import Foundation

// MARK: - Quote

public struct QuoteResponse: Codable, Equatable {
    // MARK: - Properties

    public let inAmount, outAmount: String
    public let priceImpactPct: Decimal
    public let routePlan: [RoutePlan]
    public let amount: String
    public let slippageBps: Int
    public let otherAmountThreshold, swapMode: String
    public let platformFee: PlatformFee?
    public let keyapp: KeyAppInfo?
    
    public let timeTaken: Double?
    public let contextSlot: Int?

    // MARK: - Additional properties (non Codable)

    public let _receiveAt = Date()

    // MARK: - Initializer

    public init(
        inAmount: String,
        outAmount: String,
        priceImpactPct: Decimal,
        routePlan: [RoutePlan],
        amount: String,
        slippageBps: Int,
        otherAmountThreshold: String,
        swapMode: String,
        platformFee: PlatformFee?,
        keyapp: KeyAppInfo?,
        timeTaken: Double?,
        contextSlot: Int?
    ) {
        self.inAmount = inAmount
        self.outAmount = outAmount
        self.priceImpactPct = priceImpactPct
        self.routePlan = routePlan
        self.amount = amount
        self.slippageBps = slippageBps
        self.otherAmountThreshold = otherAmountThreshold
        self.swapMode = swapMode
        self.platformFee = platformFee
        self.keyapp = keyapp
        self.timeTaken = timeTaken
        self.contextSlot = contextSlot
    }

    // MARK: - Custom Encoding

    // Custom encoding ensures that no additional properties (_receivedAt)\
    // will be included when sending request
    // If any property is missing or unexpectedly added, We got server error 500:
    // Integrity of the route has been compromised

    private enum CodingKeys: String, CodingKey {
        case inAmount, outAmount
        case priceImpactPct
        case routePlan
        case amount
        case slippageBps
        case otherAmountThreshold, swapMode
        case platformFee
        case keyapp
        case timeTaken
        case contextSlot
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        inAmount = try container.decode(String.self, forKey: .inAmount)
        outAmount = try container.decode(String.self, forKey: .outAmount)
        priceImpactPct = try container.decode(Decimal.self, forKey: .priceImpactPct)
        routePlan = try container.decode([RoutePlan].self, forKey: .routePlan)
        amount = try container.decode(String.self, forKey: .amount)
        slippageBps = try container.decode(Int.self, forKey: .slippageBps)
        otherAmountThreshold = try container.decode(String.self, forKey: .otherAmountThreshold)
        swapMode = try container.decode(String.self, forKey: .swapMode)
        platformFee = try container.decodeIfPresent(PlatformFee.self, forKey: .platformFee)
        keyapp = try container.decodeIfPresent(KeyAppInfo.self, forKey: .keyapp)
        timeTaken = try container.decodeIfPresent(Double.self, forKey: .timeTaken)
        contextSlot = try container.decodeIfPresent(Int.self, forKey: .contextSlot)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(inAmount, forKey: .inAmount)
        try container.encode(outAmount, forKey: .outAmount)
        try container.encode(priceImpactPct, forKey: .priceImpactPct)
        try container.encode(routePlan, forKey: .routePlan)
        try container.encode(amount, forKey: .amount)
        try container.encode(slippageBps, forKey: .slippageBps)
        try container.encode(otherAmountThreshold, forKey: .otherAmountThreshold)
        try container.encode(swapMode, forKey: .swapMode)
        try container.encodeIfPresent(platformFee, forKey: .platformFee)
        try container.encodeIfPresent(keyapp, forKey: .keyapp)
        try container.encodeIfPresent(timeTaken, forKey: .timeTaken)
        try container.encodeIfPresent(contextSlot, forKey: .contextSlot)
    }
}

// MARK: - RoutePlan

public struct RoutePlan: Codable, Equatable {
    public let swapInfo: SwapInfo
    public let percent: Int32
}

// MARK: - SwapInfo

public struct SwapInfo: Codable, Equatable {
    public let ammKey: String
    public let label: String?
    public let inputMint: String
    public let outputMint: String
    public let inputAmount: String
    public let outputAmount: String
    public let feeAmount: String
    public let feeMint: String
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
    public let feeBps: Int

    init(amount: String, feeBps: Int) {
        self.amount = amount
        self.feeBps = feeBps
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
