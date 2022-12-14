import Combine
import KeyAppUI
import Resolver
import RxSwift
import SolanaSwift
import TransactionParser

final class SendTransactionStatusViewModel: BaseViewModel, ObservableObject {
    @Injected private var transactionHandler: TransactionHandler
    @Injected private var priceService: PricesServiceType

    let close = PassthroughSubject<Void, Never>()
    let errorMessageTap = PassthroughSubject<Void, Never>()
    let openDetails = PassthroughSubject<SendTransactionStatusDetailsParameters, Never>()

    @Published var token: Token
    @Published var title: String = L10n.transactionSubmitted
    @Published var subtitle: String = ""
    @Published var transactionFiatAmount: String
    @Published var transactionCryptoAmount: String
    @Published var info = [(title: String, detail: String)]()
    @Published var state: State = .loading(message: L10n.itUsuallyTakes520SecondsForATransactionToComplete)

    private var currentTransaction: ParsedTransaction?
    private let disposeBag = DisposeBag()

    init(transaction: SendTransaction) {
        token = transaction.walletToken.token
        transactionFiatAmount = "-\(transaction.amountInFiat.fiatAmount())"
        transactionCryptoAmount = transaction.amount.tokenAmount(symbol: transaction.walletToken.token.symbol)

        let feeToken = transaction.payingFeeWallet.token
        let feeAmount: String? = transaction.feeInToken == .zero ? nil : transaction.feeInToken.total
            .convertToBalance(decimals: feeToken.decimals).tokenAmount(symbol: feeToken.symbol)
        let feeInfo = feeAmount ?? L10n.freePaidByKeyApp

        var recipient: String = RecipientFormatter.format(destination: transaction.recipient.address)
        if case let .username(name, domain) = transaction.recipient.category {
            recipient = RecipientFormatter.username(name: name, domain: domain)
        }
        info = [
            (title: L10n.sentTo, detail: recipient),
            (title: L10n.transactionFee, detail: feeInfo),
        ]

        super.init()
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
                self.currentTransaction = pendingTransaction?.parse(pricesService: self.priceService)
            }
            .disposed(by: disposeBag)

        errorMessageTap
            .sink { [weak self] in
                guard
                    let self = self,
                    let parsedTransaction = self.currentTransaction,
                    let error = parsedTransaction.status.getError() as? SolanaError else { return }
                var params = SendTransactionStatusDetailsParameters(
                    title: L10n.somethingWentWrong,
                    description: L10n.unknownError,
                    fee: feeAmount
                )
                switch error {
                case let .other(message) where message == "Blockhash not found":
                    params = .init(
                        title: L10n.blockhashNotFound,
                        description: L10n.theBankHasNotSeenTheGivenOrTheTransactionIsTooOldAndTheHasBeenDiscarded(
                            parsedTransaction.blockhash ?? "",
                            parsedTransaction.blockhash ?? ""
                        ),
                        fee: feeAmount
                    )
                case let .other(message) where message.contains("Instruction"):
                    params = .init(
                        title: L10n.errorProcessingInstruction0CustomProgramError0x1,
                        description: L10n.AnErrorOccuredWhileProcessingAnInstruction
                            .theFirstElementOfTheTupleIndicatesTheInstructionIndexInWhichTheErrorOccured, fee: feeAmount
                    )
                case let .other(message) where message.contains("Already processed"):
                    params = .init(
                        title: L10n.thisTransactionHasAlreadyBeenProcessed,
                        description: L10n.TheBankHasSeenThisTransactionBefore
                            .thisCanOccurUnderNormalOperationWhenAUDPPacketIsDuplicatedAsAUserErrorFromAClientNotUpdatingItsOrAsADoubleSpendAttack(parsedTransaction
                                .blockhash ?? ""),
                        fee: feeAmount
                    )
                case let .other(message):
                    params = .init(
                        title: L10n.somethingWentWrong,
                        description: message,
                        fee: feeAmount
                    )
                default:
                    break
                }
                self.openDetails.send(params)
            }
            .store(in: &subscriptions)
    }

    private func updateCompleted() {
        title = L10n.transactionSucceeded
        let text = L10n.theTransactionHasBeenSuccessfullyCompleted🤟
        state = .succeed(message: text)
    }

    private func updateError() {
        title = L10n.transactionFailed
        let text = L10n.theTransactionWasRejectedByTheSolanaBlockchain🥺
        let buttonText = L10n.tapForDetails
        let attributedError = NSMutableAttributedString(string: text, attributes: [
            .font: UIFont.font(of: .text4),
            .foregroundColor: Asset.Colors.night.color,
        ])
        attributedError.appending(
            NSMutableAttributedString(string: buttonText, attributes: [
                .font: UIFont.font(of: .text4, weight: .bold),
                .foregroundColor: Asset.Colors.rose.color,
            ])
        )
        state = .error(message: attributedError)
    }
}

extension SendTransactionStatusViewModel {
    enum State {
        case loading(message: String)
        case succeed(message: String)
        case error(message: NSAttributedString)
    }
}
