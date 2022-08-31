import Combine
import Foundation
import KeyAppUI
import SolanaSwift
import SwiftyUserDefaults
import UIKit

class BuyViewModel: ObservableObject {
    var coordinatorIO = CoordinatorIO()
    private var subscriptions = Set<AnyCancellable>()

    @Published var availableMethods = [PaymentTypeItem]()
    @Published var token: Token = .nativeSolana
    @Published var fiat: Fiat = .usd
    @Published var selectedPayment: PaymentType?

    @SwiftyUserDefault(keyPath: \.buyLastPaymentMethod, options: .cached) var lastMethod: PaymentType

    init() {
        selectedPayment = lastMethod

        availableMethods = PaymentType.allCases.filter { $0 != lastMethod }.map { $0.paymentItem() }
        availableMethods.insert(lastMethod.paymentItem(), at: 0)

        coordinatorIO.tokenSelected.sink { token in
            self.token = token
        }.store(in: &subscriptions)

        coordinatorIO.fiatSelected.sink { fiat in
            self.fiat = fiat
        }.store(in: &subscriptions)
    }

    func didSelectPayment(_ payment: PaymentTypeItem) {
        self.lastMethod = payment.type
        self.selectedPayment = payment.type
    }

    // TODO: rename
    func didTapTotal() {
        coordinatorIO.showDetail.send()
    }

    func tokenSelectTapped() {
        coordinatorIO.showTokenSelect.send()
    }

    func fiatSelectTapped() {
        coordinatorIO.showFiatSelect.send()
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

extension BuyViewModel {
    enum PaymentType: String, DefaultsSerializable, CaseIterable {
        case card
        case apple
        case bank

        func paymentItem() -> PaymentTypeItem {
            switch self {
            case .bank:
                return .init(
                    type: self,
                    fee: "1%",
                    time: "~17 hours",
                    name: "Bank transfer",
                    icon: UIImage.buyBank
                )
            case .card:
                return .init(
                    type: self,
                    fee: "4%",
                    time: "instant",
                    name: "Card",
                    icon: UIImage.buyCard
                )
            case .apple:
                return .init(
                    type: self,
                    fee: "4%",
                    time: "instant",
                    name: "Apple pay",
                    icon: UIImage.buyApple
                )
            }
        }
    }

    struct PaymentTypeItem: Equatable {
        var type: PaymentType
        var fee: String
        // TODO: rename to 'duration'
        var time: String
        var name: String
        var icon: UIImage
    }
}
