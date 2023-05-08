import Send
import SolanaSwift
import KeyAppKitCore

struct SendTransaction: RawTransactionType {
    let walletToken: SolanaAccount
    let recipient: Recipient
    let amount: Double
    let amountInFiat: Double
    
    var payingFeeWallet: SolanaAccount?
    var feeAmount: FeeAmount
    var sendViaLinkSeed: String?

    let execution: () async throws -> TransactionID

    var mainDescription: String {
        var username: String?
        if case let .username(name, domain) = recipient.category {
            username = [name, domain].joined(separator: ".")
        }
        return amount.toString(maximumFractionDigits: 9) + " " + walletToken.token
            .symbol + " → " + (username ?? recipient.address.truncatingMiddle(numOfSymbolsRevealed: 4))
    }

    init(state: SendInputState, execution: @escaping () async throws -> TransactionID) {
        walletToken = state.sourceAccount!
        recipient = state.recipient
        amount = state.amountInToken
//        fees = [
//            .init(type: .transactionFee, lamports: state.feeInToken.transaction, token: state.tokenFee),
//            .init(type: .accountCreationFee(), lamports: state.feeInToken.accountBalances, token: state.tokenFee)
//        ]
        amountInFiat = state.amountInFiat
        payingFeeWallet = state.feeWallet
        feeAmount = state.feeInToken
        sendViaLinkSeed = state.sendViaLinkSeed
        self.execution = execution
    }

    func createRequest() async throws -> String {
        try await execution()
    }
    
    // MARK: - Getters

    var isSendingViaLink: Bool {
        sendViaLinkSeed != nil
    }
}
