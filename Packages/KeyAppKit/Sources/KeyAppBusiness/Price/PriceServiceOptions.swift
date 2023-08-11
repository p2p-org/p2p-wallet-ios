import Foundation

public struct PriceServiceOptions: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let actualPrice = PriceServiceOptions(rawValue: 1 << 0)
}
