import Foundation

enum SellNavigation {
    case webPage(url: URL)
    case showPending(transactions: [SellDataServiceTransaction], fiat: Fiat)
    case swap
}

enum SellError: Error {
    case invalidURL
}
