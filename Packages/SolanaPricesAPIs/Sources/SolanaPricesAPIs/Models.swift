import Foundation

public struct CurrentPrice: Codable, Hashable {
    public init(value: Double? = nil, change24h: CurrentPrice.Change24h? = nil) {
        self.value = value
        self.change24h = change24h
    }
    
    public struct Change24h: Codable, Hashable {
        public var value: Double?
        public var percentage: Double?
    }

    public var value: Double?
    public var change24h: Change24h?
}

public struct PriceRecord: Hashable {
    public let close: Double
    public let open: Double
    public let low: Double
    public let high: Double
    public let startTime: Date

    public func converting(exchangeRate: Double) -> PriceRecord {
        PriceRecord(
            close: close * exchangeRate,
            open: open * exchangeRate,
            low: low * exchangeRate,
            high: high * exchangeRate,
            startTime: startTime
        )
    }
}

public enum Period: String, CaseIterable {
    case last1h
    case last4h
    case day
    case week
    case month
//    case year
//    case all
}
