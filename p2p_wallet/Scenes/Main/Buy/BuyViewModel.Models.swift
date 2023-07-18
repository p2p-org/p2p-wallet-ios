import Foundation
import SolanaSwift
import UIKit

extension BuyViewModel {
    struct BuyForm: Equatable {
        var token: Token
        var tokenAmount: Double?
        var fiat: Fiat
        var fiatAmount: Double?
    }

    struct PaymentTypeItem: Equatable {
        var type: PaymentType
        var fee: String
        var duration: String
        var name: String
        var icon: UIImage
    }
}
