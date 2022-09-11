import Foundation

enum PaymentType: String, DefaultsSerializable, CaseIterable {
    case card
    case bank

    case gbpBank

    static var allCases: [PaymentType] = [.card, .bank]
}

extension PaymentType {
    func paymentItem() -> BuyViewModel.PaymentTypeItem {
        switch self {
        case .bank, .gbpBank:
            return .init(
                type: self,
                fee: "1%",
                duration: "~17 hours",
                name: "Bank transfer",
                icon: UIImage.buyBank
            )
        case .card:
            return .init(
                type: self,
                fee: "4.5%",
                duration: "Instant",
                name: "Card",
                icon: UIImage.buyCard
            )
        }
    }
}
