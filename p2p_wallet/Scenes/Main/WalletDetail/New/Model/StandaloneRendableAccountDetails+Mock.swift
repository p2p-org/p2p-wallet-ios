import Foundation

struct MockRendableAccountDetails: RendableAccountDetails {
    var title: String
    var amountInToken: String
    var amountInFiat: String
    var actions: [RendableAccountDetailsAction]
    var onAction: (RendableAccountDetailsAction) -> Void
}
