import Foundation

enum SellNavigation {
    case webPage(url: URL)
    case showPending(transactions: [any ProviderTransaction])
}

enum SellError: Error {
    case invalidURL
}
