import Foundation
import SolanaSwift

extension BuyViewModel {
    struct TotalResult {
        var total: String
        var totalCurrency: Fiat
        var token: Token
        var fiat: Fiat
        var tokenAmount: String
        var fiatAmmount: String
    }

    // MARK: -

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
