import Foundation
import Resolver
import KeyAppBusiness
import SolanaSwift

protocol StrigaConfirmableTransactionType: RawTransactionType, Equatable {
    var challengeId: String { get }
}

/// Striga Claim trasaction type
protocol StrigaClaimTransactionType: RawTransactionType, Equatable {
    var challengeId: String { get }
    var token: Token? { get }
    var amount: Double? { get }
    var feeAmount: FeeAmount { get }
    var fromAddress: String { get }
    var receivingAddress: String { get }
}

extension StrigaClaimTransactionType {
    var amountInFiat: Double? {
        guard let token else { return nil}
        guard let value = Resolver.resolve(SolanaPriceService.self)
            .getPriceFromCache(token: token, fiat: Defaults.fiat.rawValue)?.value else { return nil }
        return value * amount
    }
}

/// Default implemetation of `StrigaClaimTransactionType`
struct StrigaClaimTransaction: StrigaClaimTransactionType, StrigaConfirmableTransactionType {

    // MARK: - Properties

    let challengeId: String
    let token: Token?
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
    var token: Token { get }
    var IBAN: String { get }
    var BIC: String { get }
    var feeAmount: FeeAmount { get }
    var amount: Double { get }
}

extension StrigaWithdrawTransactionType {
    var amountInFiat: Double? {
        guard let value = Resolver.resolve(SolanaPriceService.self)
            .getPriceFromCache(token: token, fiat: Defaults.fiat.rawValue)?.value else { return amount }
        return value * amount
    }
}

/// Default implemetation of `StrigaClaimTransactionType`
struct StrigaWithdrawTransaction: StrigaWithdrawTransactionType, StrigaConfirmableTransactionType {

    // MARK: - Properties

    var challengeId: String
    var IBAN: String
    var BIC: String
    var amount: Double
    let token: Token = .usdc
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
    let token: Token = .usdc
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
