import SolanaSwift
import Send

struct SendInputParameters {
    let source: SendSource
    let recipient: Recipient
    let preChosenWallet: Wallet?
    let preChosenAmount: Double?
    let pushedWithoutRecipientSearchView: Bool
    let allowSwitchingMainAmountType: Bool
}
