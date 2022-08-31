import Combine
import Foundation
import KeyAppUI
import SolanaSwift
import UIKit

struct BuyMethodItem {
    var fee: String
    var time: String
    var name: String
    var icon: UIImage
}

class BuyViewModel: ObservableObject {
    var coordinatorIO = CoordinatorIO()
    private var subscriptions = Set<AnyCancellable>()

    @Published var availableMethods = [BuyMethodItem]()
    @Published var token: Token = .nativeSolana
    @Published var fiat: Fiat = .usd

    init() {
        availableMethods.append(
            .init(
                fee: "4%",
                time: "1 day",
                name: "Bank transfer",
                icon: UIImage(named: "buy-bank")!
            )
        )
        availableMethods.append(
            .init(
                fee: "1%",
                time: "instant",
                name: "Card",
                icon: UIImage(named: "buy-card")!
            )
        )
        availableMethods.append(
            .init(
                fee: "0%",
                time: "instant",
                name: "ApplePay",
                icon: UIImage(named: "buy-apple")!
            )
        )

        coordinatorIO.tokenSelected.sink { token in
            self.token = token
        }.store(in: &subscriptions)

        coordinatorIO.fiatSelected.sink { fiat in
            self.fiat = fiat
        }.store(in: &subscriptions)
    }

    func didTapTotal() {
        coordinatorIO.showDetail.send()
    }

    func tokenSelectTapped() {
        coordinatorIO.showTokenSelect.send()
    }

    func fiatSelectTapped() {
        coordinatorIO.showFiatSelect.send()
    }

    enum PaymentType {
        case card
        case apple
        case bank
    }
}

extension BuyViewModel {
    struct CoordinatorIO {
        // Input
        var showDetail = PassthroughSubject<Void, Never>()
        var showTokenSelect = PassthroughSubject<Void, Never>()
        var showFiatSelect = PassthroughSubject<Void, Never>()
        // Output
        var tokenSelected = PassthroughSubject<Token, Never>()
        var fiatSelected = PassthroughSubject<Fiat, Never>()
    }
}
