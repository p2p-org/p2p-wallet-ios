import Foundation

public enum SellDataServiceStatus {
    case initialized
    case updating
    case ready
    case error(Error)
    
    public var isReady: Bool {
        switch self {
        case .ready:
            return true
        default:
            return false
        }
    }
}

public protocol ProviderCurrency: Equatable {
    var id: String { get }
    var name: String { get }
    var code: String { get }
    var minSellAmount: Double? { get }
    var maxSellAmount: Double? { get }
}

public protocol ProviderFiat: Equatable {
    var code: String { get }
    var rawValue: String { get }
}

public protocol ProviderTransaction: Hashable {
    var id: String { get }
//    var status: String { get }
    var baseCurrencyAmount: Double { get }
    var depositWalletId: String { get }
}

public struct SellDataServiceTransaction: Hashable {
    public var id: String
    public var createdAt: Date?
    public var status: Status
    public var baseCurrencyAmount: Double
    public var quoteCurrencyAmount: Double
    public var usdRate: Double
    public var eurRate: Double
    public var gbpRate: Double
    public var depositWallet: String
    public var fauilureReason: String?
    
    public enum Status: String {
        case waitingForDeposit
        case pending
        case failed
        case completed
    }
}

public enum SellDataServiceError: Error {
    case couldNotLoadSellData
}

public protocol SellPriceProvider {
    func getCurrentPrice(for tokenSymbol: String) -> Double?
}
