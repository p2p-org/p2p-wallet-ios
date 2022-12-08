import Foundation

enum SellNavigation: Equatable {
    case webPage(url: URL)
    case showPending
}

enum SellError: Error {
    case invalidURL
}
