import RxSwift
import Send
import SolanaSwift

struct SendTransaction: RawTransactionType {
    let walletToken: Wallet
    let recipient: Recipient
    let amount: Double
    let amountInFiat: Double
    let payingFeeWallet: Wallet
    let feeInToken: FeeAmount

    let execution: () async throws -> TransactionID

    var mainDescription: String {
        var username: String?
        if case let .username(name, domain) = recipient.category {
            username = [name, domain].joined(separator: ".")
        }
        return amount.toString(maximumFractionDigits: 9) + " " + walletToken.token
            .symbol + " → " + (username ?? recipient.address.truncatingMiddle(numOfSymbolsRevealed: 4))
    }

    var networkFees: (total: Lamports, token: Token)? {
        (total: feeInToken.total, token: payingFeeWallet.token)
    }

    init(state: SendInputState, execution: @escaping () async throws -> TransactionID) {
        walletToken = state.sourceWallet!
        recipient = state.recipient
        amount = state.amountInToken
        payingFeeWallet = state.feeWallet!
        feeInToken = state.feeInToken
        amountInFiat = state.amountInFiat
        self.execution = execution
    }

    func createRequest() -> Single<String> {
        Single.async { try await execution() }
    }
}
