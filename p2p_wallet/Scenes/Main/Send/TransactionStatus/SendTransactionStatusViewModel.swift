import SolanaSwift
import KeyAppUI
import Combine
import Resolver
import RxSwift

final class SendTransactionStatusViewModel: ObservableObject {
    @Injected private var transactionHandler: TransactionHandler

    let close = PassthroughSubject<Void, Never>()

    @Published var token: Token
    @Published var title: String = L10n.transactionSubmitted
    @Published var subtitle: String = ""
    @Published var transactionFiatAmount: String
    @Published var transactionCryptoAmount: String
    @Published var info = [(title: String, detail: String)]()
    @Published var state: State = .loading(message: L10n.itUsuallyTakes520SecondsForATransactionToComplete)

    private let disposeBag = DisposeBag()

    init(transaction: SendTransaction) {
        self.token = transaction.walletToken.token
        self.transactionFiatAmount = "-\(transaction.amountInFiat.fiatAmount())"
        self.transactionCryptoAmount = transaction.amount.tokenAmount(symbol: transaction.walletToken.token.symbol)

        let feeToken = transaction.payingFeeWallet.token
        let feeInfo: String = transaction.feeInToken == .zero
        ? L10n.freePaidByKeyApp
        : transaction.feeInToken.total.convertToBalance(decimals: feeToken.decimals).tokenAmount(symbol: feeToken.symbol)
        info = [
            (title: L10n.sentTo, detail: transaction.recipient.address),
            (title: L10n.transactionFee, detail: feeInfo),
        ]

        let transactionIndex = transactionHandler.sendTransaction(transaction)
        transactionHandler.observeTransaction(transactionIndex: transactionIndex)
            .subscribe { [weak self] pendingTransaction in
                guard let self = self else { return }
                self.subtitle = pendingTransaction?.sentAt.string(withFormat: "MMMM dd, yyyy @ HH:mm a") ?? ""
                switch pendingTransaction?.status {
                case .error:
                    self.updateError()
                case .finalized:
                    self.updateCompleted()
                default:
                    break
                }
            }
            .disposed(by: disposeBag)
    }

    private func updateCompleted() {
        self.title = L10n.transactionSucceeded
        let text = L10n.theTransactionHasBeenSuccessfullyCompleted🤟
        self.state = .succeed(message: text)
    }

    private func updateError() {
        self.title = L10n.transactionFailed
        let text = L10n.theTransactionWasRejectedByTheSolanaBlockchain🥺
        let buttonText = L10n.tapForDetails
        let attributedError = NSMutableAttributedString(string: text, attributes: [
            .font: UIFont.font(of: .text4),
            .foregroundColor: Asset.Colors.night.color
        ])
        attributedError.appending(
            NSMutableAttributedString(string: buttonText, attributes: [
                .font: UIFont.font(of: .text4, weight: .bold),
                .foregroundColor: Asset.Colors.rose.color
            ])
        )
        self.state = .error(message: attributedError)
    }
}

extension SendTransactionStatusViewModel {
    enum State {
        case loading(message: String)
        case succeed(message: String)
        case error(message: NSAttributedString)
    }
}
