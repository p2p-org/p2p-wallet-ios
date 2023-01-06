import Foundation
import Sell
import SolanaSwift
import Send

enum SellNavigation {
    case webPage(url: URL)
    case showPending(transactions: [SellDataServiceTransaction], fiat: any ProviderFiat)
    case send(from: Wallet, to: Recipient, amount: Double, sellTransaction: SellDataServiceTransaction)
    case swap
}

enum SellError: Error {
    case invalidURL
}
