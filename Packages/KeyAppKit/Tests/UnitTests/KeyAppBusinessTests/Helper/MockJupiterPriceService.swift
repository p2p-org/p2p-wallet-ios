import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore

final class MockJupiterPriceService: JupiterPriceService {
    func getPrice(token: KeyAppKitCore.AnyToken, fiat: String) async throws -> KeyAppKitCore.TokenPrice? {
        let result = try await getPrices(tokens: [token], fiat: fiat)
        return result.values.first ?? nil
    }

    func getPrices(tokens _: [KeyAppKitCore.AnyToken],
                   fiat _: String) async throws -> [KeyAppKitCore.SomeToken: KeyAppKitCore.TokenPrice]
    {
        [:]
    }

    let timerPublisher: Timer.TimerPublisher = .init(interval: 5, runLoop: .main, mode: .default)

    var onChangePublisher: AnyPublisher<Void, Never> {
        timerPublisher
            .autoconnect()
            .map { _ in }
            .eraseToAnyPublisher()
    }
}
