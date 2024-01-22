import Foundation

public protocol SellDataServiceProvider {
    associatedtype Transaction: ProviderTransaction
    associatedtype Currency: ProviderCurrency
    associatedtype Fiat: ProviderFiat
    associatedtype Region: ProviderRegion

    func sellTransactions(externalCustomerId: String) async throws -> [Transaction]
    func detailSellTransaction(id: String) async throws -> Transaction
    func deleteSellTransaction(id: String) async throws
}
