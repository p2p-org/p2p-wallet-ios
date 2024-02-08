import Combine
import Foundation
import SolanaSwift

struct MockedRendableDetailTransaction: RenderableTransactionDetail {
    var status: TransactionDetailStatus
    var title: String
    var subtitle: String
    var icon: TransactionDetailIcon
    var amountInFiat: TransactionDetailChange
    var amountInToken: String
    var extra: [TransactionDetailExtraInfo]
    var actions: [TransactionDetailAction]
    var bottomActions: [TransactionBottomAction]
    var url: String?

    init(
        status: TransactionDetailStatus,
        title: String,
        subtitle: String,
        icon: TransactionDetailIcon,
        amountInFiat: TransactionDetailChange,
        amountInToken: String,
        extra: [TransactionDetailExtraInfo],
        actions: [TransactionDetailAction],
        bottomActions: [TransactionBottomAction] = [.done]
    ) {
        self.status = status
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.amountInFiat = amountInFiat
        self.amountInToken = amountInToken
        self.extra = extra
        self.actions = actions
        self.bottomActions = bottomActions
    }

    static func send() -> Self {
        .init(
            status: .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted🤟),
            title: "Transaction submitted",
            subtitle: "August 22, 2022 @ 08:08",
            icon: .single(URL(string: TokenMetadata.nativeSolana.logoURI!)!),
            amountInFiat: .negative("-$122.12"),
            amountInToken: "5.21 SOL",
            extra: [
                .init(title: L10n.sendTo, values: [.init(text: "@kirill.key")], copyableValue: "@kirill.key"),
                .init(title: L10n.transactionFee, values: [.init(text: L10n.freePaidByKeyApp)]),
            ],
            actions: [
                .share,
                .explorer,
            ]
        )
    }
}
