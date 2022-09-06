import Combine
import Foundation
import KeyAppUI
import Resolver
import SolanaSwift
import SwiftyUserDefaults

class NewBuyViewModel: ObservableObject {
    @Published var isLoading: Bool = false

    @Published var cryptoInput: String = "0"
    @Published var fiatInput: String = "0"

    @Published var cryptoValue: BuyCryptoCurrency = .init(value: 0, currency: .sol)
    @Published var fiatValue: BuyFiatValue = .init(value: 0, currency: .usd)

    @Published var paymentMethods: [BuyPaymentMethod] = [.card, .bank]
    @Published var selectedPaymentMethod: BuyPaymentMethod = .card

    @Published var total: BuyFiatValue = .init(value: 0, currency: .usd)

    struct Coordinator {
        // Input
        var showDetail = PassthroughSubject<Void, Never>()
        var showTokenSelect = PassthroughSubject<Void, Never>()
        var showFiatSelect = PassthroughSubject<Void, Never>()
        // Output
        var tokenSelected = PassthroughSubject<Token, Never>()
        var fiatSelected = PassthroughSubject<Fiat, Never>()
    }

    let coordinator: Coordinator = .init()

    // View Input
    func showDetail() { coordinator.showDetail.send() }
}
