import Foundation
import Sell
import SolanaSwift

extension PricesService: SellPriceProvider {
    func getCurrentPrice(for tokenSymbol: String) -> Double? {
        guard let token = Token.moonpaySellSupportedTokens.first(where: { $0.symbol == tokenSymbol })
        else { return nil }
        
        return currentPrice(mint: token.address)?.value
    }
}
