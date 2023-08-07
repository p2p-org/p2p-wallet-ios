import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import SolanaSwift

protocol StrigaConfirmableTransactionType: RawTransactionType, Equatable {
    var challengeId: String { get }
}

/// Striga Claim trasaction type
protocol StrigaClaimTransactionType: RawTransactionType, Equatable {
    var challengeId: String { get }
    var token: TokenMetadata? { get }
    var tokenPrice: TokenPrice? { get }
    var amount: Double? { get }
    var feeAmount: FeeAmount { get }
    var fromAddress: String { get }
    var receivingAddress: String { get }
}

extension StrigaClaimTransactionType {
    var amountInFiat: Double? {
        guard let tokenPrice = tokenPrice?.doubleValue else { return nil }
        return (amount ?? 0) * tokenPrice
    }
}

/// Default implemetation of `StrigaClaimTransactionType`
struct StrigaClaimTransaction: StrigaClaimTransactionType, StrigaConfirmableTransactionType {
    // MARK: - Properties

    let challengeId: String
    let token: TokenMetadata?
    var tokenPrice: TokenPrice?
    let amount: Double?
    let feeAmount: FeeAmount
    let fromAddress: String
    let receivingAddress: String

    var mainDescription: String {
        ""
    }

    // MARK: - Methods

    func createRequest() async throws -> String {
        // get transaction from proxy api

        // sign transaction

        // TODO: - send to blockchain
        try? await Task.sleep(seconds: 1)
        return .fakeTransactionSignature(id: UUID().uuidString)
    }
}

protocol StrigaWithdrawTransactionType: RawTransactionType {
    var token: TokenMetadata? { get }
    var tokenPrice: TokenPrice? { get }
    var IBAN: String { get }
    var BIC: String { get }
    var feeAmount: FeeAmount { get }
    var amount: Double { get }
}

extension StrigaWithdrawTransactionType {
    var amountInFiat: Double? {
        guard let tokenPrice = tokenPrice?.doubleValue else { return nil }
        return (amount ?? 0) * tokenPrice
    }
}

/// Default implemetation of `StrigaClaimTransactionType`
struct StrigaWithdrawTransaction: StrigaWithdrawTransactionType, StrigaConfirmableTransactionType {
    // MARK: - Properties

    var challengeId: String
    var IBAN: String
    var BIC: String
    var amount: Double
    let token: TokenMetadata?
    let tokenPrice: TokenPrice?
    let feeAmount: FeeAmount
    var mainDescription: String {
        ""
    }

    // MARK: - Methods

    func createRequest() async throws -> String {
        // get transaction from proxy api

        // sign transaction

        // TODO: - send to blockchain
        try? await Task.sleep(seconds: 1)
        return .fakeTransactionSignature(id: UUID().uuidString)
    }
}

extension StrigaClaimTransaction: Equatable {}

/// Used to wrap Send transaction into Striga Withdraw format
struct StrigaWithdrawSendTransaction: StrigaWithdrawTransactionType, RawTransactionType {
    var sendTransaction: SendTransaction
    var IBAN: String
    var BIC: String
    var amount: Double
    var token: TokenMetadata? = .usdc
    var tokenPrice: TokenPrice?
    let feeAmount: FeeAmount
    var mainDescription: String {
        ""
    }

    // MARK: - Methods

    func createRequest() async throws -> String {
        // get transaction from proxy api

        // sign transaction

        // TODO: - send to blockchain
        try? await Task.sleep(seconds: 1)
        return .fakePausedTransactionSignaturePrefix + UUID().uuidString
    }
}
