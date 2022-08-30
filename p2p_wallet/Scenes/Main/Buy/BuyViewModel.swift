import Foundation
import UIKit
import Combine
import KeyAppUI

struct BuyMethodItem {
    var fee: String
    var time: String
    var name: String
    var icon: UIImage
}

class BuyViewModel: ObservableObject {
    
    var coordinatorIO = CoordinatorIO()
    
    @Published var availableMethods = [BuyMethodItem]()
    
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
    }
    
    func didTapTotal() {
        coordinatorIO.didTapTotal.send()
    }
    
    enum PaymentType {
        case card
        case apple
        case bank
    }
}

extension BuyViewModel {
    struct CoordinatorIO {
        var didTapTotal = PassthroughSubject<Void, Never>()
    }
}
