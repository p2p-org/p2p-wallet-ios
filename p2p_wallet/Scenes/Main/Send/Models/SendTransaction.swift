import SolanaSwift
import RxSwift
import Send

struct SendTransaction: RawTransactionType {
    let transactionId: TransactionID
    let walletToken: Wallet
    let recipient: Recipient
    let amount: Double
    let amountInFiat: Double
    let payingFeeWallet: Wallet
    let feeInToken: FeeAmount

    var mainDescription: String {
        var username: String?
        if case let .username(name, domain) = recipient.category {
            username = [name, domain].joined(separator: ".")
        }
        return amount.toString(maximumFractionDigits: 9) + " " + walletToken.token.symbol + " → " + (username ?? recipient.address.truncatingMiddle(numOfSymbolsRevealed: 4))
    }

    var networkFees: (total: Lamports, token: Token)? {
        (total: feeInToken.total, token: payingFeeWallet.token)
    }

    init(transactionId: TransactionID, state: SendInputState) {
        self.transactionId = transactionId
        self.walletToken = state.sourceWallet!
        self.recipient = state.recipient
        self.amount = state.amountInToken
        self.payingFeeWallet = state.feeWallet!
        self.feeInToken = state.feeInToken
        self.amountInFiat = state.amountInFiat
    }

    func createRequest() -> RxSwift.Single<String> {
        return Single.just(transactionId)
    }
}
