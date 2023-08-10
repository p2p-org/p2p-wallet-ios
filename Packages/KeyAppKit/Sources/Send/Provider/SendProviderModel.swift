import Foundation
import KeyAppKitCore

public enum SwapMode: String, Codable, Hashable {
    case exactIn = "ExactIn"
    case exactOut = "ExactOut"
}

public enum FeePayer: String, Codable, Hashable {
    case service = "Service"
    case user = "User"
}

public struct TransferOptions: Codable, Hashable {
    let swapMode: SwapMode
    let feePayer: FeePayer

    public init(swapMode: SwapMode, feePayer: FeePayer) {
        self.swapMode = swapMode
        self.feePayer = feePayer
    }
}

public struct SendResponse: Codable, Hashable {
    let transaction: String
    let blockhash: String
    let expiresAt: UInt64
    let signature: String

    let recipientGetsAmount: TokenAmount
    let totalAmount: TokenAmount

    let networkFee: Fee
    let tokenAccountRent: Fee?

    // let transactionDetails: TransactionDetails
    // let transferAmounts: TransferAmounts
    // let fees: TransferFees
}

public struct TransactionDetails: Codable, Hashable {
    public let transaction: String
    public let blockhash: String
    public let expiresAt: UInt64
    public let signature: String
}

public struct TransferAmounts: Codable, Hashable {
    public let recipientGetsAmount: TokenAmount
    public let totalAmount: TokenAmount
}

public struct TransferFees: Codable, Hashable {
    public let networkFee: Fee
    public let tokenAccountRent: Fee?
}

public enum FeeSource: String, Codable, Hashable {
    case serviceCoverage = "ServiceCoverage"
    case userCompensated = "UserCompensated"
    case user = "User"
}

public struct Fee: Codable, Hashable {
    public let source: FeeSource
    public let amount: TokenAmount
}

public struct TokenAmount: Codable, Hashable {
    public let amount: String
    public let usdAmount: String
    public let mint: String

    public let symbol: String
    public let name: String
    public let decimals: UInt8

    // let meta: SolanaToken
}

extension TokenAmount: CryptoAmountConvertible {
    public var asCryptoAmount: CryptoAmount {
        let key: TokenPrimaryKey
        if mint == "So11111111111111111111111111111111111111112" {
            key = .native
        } else {
            key = .contract(mint)
        }

        return CryptoAmount(
            bigUIntString: amount,
            token: SomeToken(tokenPrimaryKey: key, symbol: symbol, name: name, decimals: decimals, network: .solana)
        )
    }
}
