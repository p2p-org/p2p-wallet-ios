import Foundation

// MARK: - Quote

public struct QuoteResponse: Codable, Equatable {
    // MARK: - Properties

    public let inAmount, outAmount: String
    public let inputMint, outputMint: String
    public let priceImpactPct: Decimal
    public let routePlan: [RoutePlan]
    public let slippageBps: Int
    public let otherAmountThreshold, swapMode: String
    public let platformFee: PlatformFee?
    public let keyapp: KeyAppInfo?

    public let message: String?
    public let timeTaken: Double?
    public let contextSlot: Int?

    // MARK: - Additional properties (non Codable)

    public let _receiveAt = Date()

    // MARK: - Initializer

    public init(
        inAmount: String,
        outAmount: String,
        inputMint: String,
        outputMint: String,
        priceImpactPct: Decimal,
        routePlan: [RoutePlan],
        slippageBps: Int,
        otherAmountThreshold: String,
        swapMode: String,
        platformFee: PlatformFee?,
        keyapp: KeyAppInfo?,
        message: String?,
        timeTaken: Double?,
        contextSlot: Int?
    ) {
        self.inAmount = inAmount
        self.outAmount = outAmount
        self.inputMint = inputMint
        self.outputMint = outputMint
        self.priceImpactPct = priceImpactPct
        self.routePlan = routePlan
        self.slippageBps = slippageBps
        self.otherAmountThreshold = otherAmountThreshold
        self.swapMode = swapMode
        self.platformFee = platformFee
        self.keyapp = keyapp

        self.message = message
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
        case inputMint, outputMint
        case priceImpactPct
        case routePlan
        case slippageBps
        case otherAmountThreshold, swapMode
        case platformFee
        case keyapp

        case message
        case timeTaken
        case contextSlot
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        inAmount = try container.decode(String.self, forKey: .inAmount)
        outAmount = try container.decode(String.self, forKey: .outAmount)

        inputMint = try container.decode(String.self, forKey: .inputMint)
        outputMint = try container.decode(String.self, forKey: .outputMint)

        priceImpactPct = try Decimal(string: container.decode(String.self, forKey: .priceImpactPct)) ?? 0.0
        routePlan = try container.decode([RoutePlan].self, forKey: .routePlan)
        slippageBps = try container.decode(Int.self, forKey: .slippageBps)
        otherAmountThreshold = try container.decode(String.self, forKey: .otherAmountThreshold)
        swapMode = try container.decode(String.self, forKey: .swapMode)
        platformFee = try container.decodeIfPresent(PlatformFee.self, forKey: .platformFee)
        keyapp = try container.decodeIfPresent(KeyAppInfo.self, forKey: .keyapp)

        message = try container.decodeIfPresent(String.self, forKey: .message)
        timeTaken = try container.decodeIfPresent(Double.self, forKey: .timeTaken)
        contextSlot = try container.decodeIfPresent(Int.self, forKey: .contextSlot)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(inAmount, forKey: .inAmount)
        try container.encode(outAmount, forKey: .outAmount)

        try container.encode(inputMint, forKey: .inputMint)
        try container.encode(outputMint, forKey: .outputMint)

        try container.encode("\(priceImpactPct)", forKey: .priceImpactPct)
        try container.encode(routePlan, forKey: .routePlan)
        try container.encode(slippageBps, forKey: .slippageBps)
        try container.encode(otherAmountThreshold, forKey: .otherAmountThreshold)
        try container.encode(swapMode, forKey: .swapMode)
        try container.encodeIfPresent(platformFee, forKey: .platformFee)
        try container.encodeIfPresent(keyapp, forKey: .keyapp)

        try container.encodeIfPresent(message, forKey: .message)
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
    public let inAmount: String
    public let outAmount: String
    public let feeAmount: String
    public let feeMint: String
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

// MARK: - KeyApp

public struct KeyAppInfo: Codable, Equatable {
    public let fee: String
    public let fees: Fees
    public let refundableFee: String
    public let _hash: String
}

public struct Fees: Codable, Equatable {
    public let signatureFee: UInt64
    public let ataDeposits: [UInt64]
    public let totalFeeAndDeposits: UInt64
    public let minimumSOLForTransaction: UInt64
}
