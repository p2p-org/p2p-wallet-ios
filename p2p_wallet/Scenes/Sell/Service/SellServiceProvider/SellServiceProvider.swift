import Foundation

public protocol ProviderCurrency {
    var id: String { get }
    var name: String { get }
    var code: String { get }
    var minSellAmount: Double? { get }
    var maxSellAmount: Double? { get }
}

public protocol ProviderTransaction: Equatable {
    var id: String { get }
//    var status: String { get }
    var baseCurrencyAmount: Double { get }
    var depositWalletId: String { get }
}

public protocol SellDataServiceProvider {
    associatedtype Transaction: ProviderTransaction
    associatedtype Currency: ProviderCurrency

    func sellTransactions(externalTransactionId: String) async throws -> [Transaction]
    func detailSellTransaction(id: String) async throws -> Transaction
    func deleteSellTransaction(id: String) async throws
}


extension SellDataServiceTransaction {
    enum Status: String {
        case waitingForDeposit
        case pending
        case failed
        case completed
    }
}
