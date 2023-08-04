import Foundation
import KeyAppKitCore

public extension PriceService {
    func getPrice(
        token: AnyToken,
        fiat: String
    ) async throws -> TokenPrice? {
        try await getPrice(token: token, fiat: fiat, options: [])
    }

    func getPrices(
        tokens: [AnyToken],
        fiat: String
    ) async throws -> [SomeToken: TokenPrice] {
        try await getPrices(tokens: tokens, fiat: fiat, options: [])
    }
}
