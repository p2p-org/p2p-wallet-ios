import SolanaSwift
import Send

struct SendInputParameters {
    let source: SendSource
    let recipient: Recipient
    let preChosenWallet: Wallet?
    let preChosenAmount: Double?
    let pushedWithoutRecipientSearchView: Bool
    let allowSwitchingMainAmountType: Bool

    init(
        source: SendSource,
        recipient: Recipient,
        preChosenWallet: Wallet?,
        preChosenAmount: Double?,
        pushedWithoutRecipientSearchView: Bool,
        allowSwitchingMainAmountType: Bool
    ) {
        self.source = source
        self.recipient = recipient
        self.preChosenWallet = preChosenWallet
        self.preChosenAmount = preChosenAmount
        self.pushedWithoutRecipientSearchView = pushedWithoutRecipientSearchView
        self.allowSwitchingMainAmountType = allowSwitchingMainAmountType
    }
}
