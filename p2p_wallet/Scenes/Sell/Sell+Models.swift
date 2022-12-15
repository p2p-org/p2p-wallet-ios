import Foundation

enum SellNavigation {
    case webPage(url: URL)
    case showPending(transactions: [any ProviderTransaction])
    case swap
}

enum SellError: Error {
    case invalidURL
}
