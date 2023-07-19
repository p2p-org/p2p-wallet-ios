import Foundation

/// Configuration for fee relayer
public struct FeeRelayerConfiguration {
    let additionalPaybackFee: UInt64
    
    let operationType: StatsInfo.OperationType
    let currency: String?

    /// Automatically payback to fee relay.
    /// Set false if transaction has already pay back instruction
    let autoPayback: Bool

    public init(
        additionalPaybackFee: UInt64 = 0,
        operationType: StatsInfo.OperationType,
        currency: String? = nil,
        autoPayback: Bool = true
    ) {
        self.additionalPaybackFee = additionalPaybackFee
        self.operationType = operationType
        self.currency = currency
        self.autoPayback = autoPayback
    }
}
