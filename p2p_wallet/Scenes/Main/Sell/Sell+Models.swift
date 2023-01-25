import Foundation
import Sell

enum SellNavigation {
    case webPage(url: URL)
    case showPending(transactions: [SellDataServiceTransaction], fiat: any ProviderFiat)
    case swap
    case moonpayInfo
}

enum SellError: Error {
    case invalidURL
}
