import Foundation
import SolanaSwift

public struct RelayContext: Hashable, Codable {
    public let minimumRelayAccountBalance: UInt64
    public let feePayerAddress: PublicKey
    public let lamportsPerSignature: UInt64
    public let relayAccountStatus: RelayAccountStatus
    public var usageStatus: UsageStatus

    public init(
        minimumRelayAccountBalance: UInt64,
        feePayerAddress: PublicKey,
        lamportsPerSignature: UInt64,
        relayAccountStatus: RelayAccountStatus,
        usageStatus: UsageStatus
    ) {
        self.minimumRelayAccountBalance = minimumRelayAccountBalance
        self.feePayerAddress = feePayerAddress
        self.lamportsPerSignature = lamportsPerSignature
        self.relayAccountStatus = relayAccountStatus
        self.usageStatus = usageStatus
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(minimumRelayAccountBalance)
        hasher.combine(feePayerAddress)
        hasher.combine(lamportsPerSignature)
    }
}
