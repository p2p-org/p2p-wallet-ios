import AnalyticsManager
import Combine
import FeeRelayerSwift
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import KeyAppUI
import Resolver
import SolanaSwift
import UIKit

final class SendTransactionStatusViewModel: BaseViewModel, ObservableObject {
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var transactionHandler: TransactionHandler
    @Injected private var priceService: PriceService

    let close = PassthroughSubject<Void, Never>()
    let errorMessageTap = PassthroughSubject<Void, Never>()
    let openDetails = PassthroughSubject<SendTransactionStatusDetailsParameters, Never>()

    @Published var token: SolanaToken
    @Published var title: String = L10n.transactionSubmitted
    @Published var subtitle: String = ""
    @Published var transactionFiatAmount: String
    @Published var transactionCryptoAmount: String
    @Published var info = [(title: String, detail: String)]()
    @Published var state: State = .loading(message: L10n.itUsuallyTakesFewSecondsForATransactionToComplete)
    @Published var closeButtonTitle: String = L10n.done

    private var currentTransactionError: Error?

    init(transaction: SendTransaction) {
        token = transaction.walletToken.token

        if transaction.amountInFiat == 0.0 {
            transactionFiatAmount = transaction.amount
                .tokenAmountFormattedString(symbol: transaction.walletToken.token.symbol)
            transactionCryptoAmount = ""
        } else {
            transactionFiatAmount =
                "-\(transaction.amountInFiat.fiatAmountFormattedString(roundingMode: .down, customFormattForLessThan1E_2: true))"
            transactionCryptoAmount = transaction.amount
                .tokenAmountFormattedString(symbol: transaction.walletToken.token.symbol)
        }

        let feeToken = transaction.payingFeeWallet?.token
        let feeAmount: String? = transaction.feeAmount == .zero ? nil : transaction.feeAmount.total
            .convertToBalance(decimals: feeToken?.decimals).tokenAmountFormattedString(symbol: feeToken?.symbol ?? "")
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
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] pendingTransaction in
                guard let self = self else { return }
                self.subtitle = pendingTransaction?.sentAt.string(
                    withFormat: "MMMM dd, yyyy @ HH:mm",
                    locale: Locale.base
                ) ?? ""

                self.currentTransactionError = nil
                switch pendingTransaction?.status {
                case .sending:
                    break
                case let .error(error):
                    self.currentTransactionError = error
                    self.update(error: error)
                default:
                    self.updateCompleted()
                }
            })
            .store(in: &subscriptions)

        transactionHandler.observeTransaction(transactionIndex: transactionIndex)
            .compactMap { $0?.transactionId }
            .prefix(1)
            .sink(receiveValue: { [weak self] signature in
                self?.logSend(event: transaction.analyticEvent, signature: signature)
            })
            .store(in: &subscriptions)

        errorMessageTap
            .sink { [weak self] in
                guard let self = self else { return }
                var params = SendTransactionStatusDetailsParameters(
                    title: L10n.somethingWentWrong,
                    description: L10n.unknownError
                )

                guard let error = self.currentTransactionError
                else {
                    self.openDetails.send(params)
                    return
                }

                if let error = error as? FeeRelayerError,
                   error.message == "Topping up is successfull, but the transaction failed"
                {
                    params = .init(title: L10n.somethingWentWrong, description: L10n.unknownError, fee: feeAmount)
                } else if let error = error as? APIClientError {
                    switch error {
                    case .blockhashNotFound:
                        params = .init(
                            title: L10n.blockhashNotFound,
                            description: L10n.theBankHasNotSeenTheGivenOrTheTransactionIsTooOldAndTheHasBeenDiscarded(
                                "", // blockhash ?? "",
                                "" // blockhash ?? ""
                            )
                        )
                    case let .responseError(response) where response.message?.contains("Instruction") == true:
                        params = .init(
                            title: L10n.errorProcessingInstruction0CustomProgramError0x1,
                            description: L10n.AnErrorOccuredWhileProcessingAnInstruction
                                .theFirstElementOfTheTupleIndicatesTheInstructionIndexInWhichTheErrorOccured
                        )
                    case let .responseError(response) where response.message?.contains("Already processed") == true:
                        params = .init(
                            title: L10n.thisTransactionHasAlreadyBeenProcessed,
                            description: L10n.TheBankHasSeenThisTransactionBefore
                                .thisCanOccurUnderNormalOperationWhenAUDPPacketIsDuplicatedAsAUserErrorFromAClientNotUpdatingItsOrAsADoubleSpendAttack(
                                    "" // blockhash ?? ""
                                )
                        )
                    case let .responseError(response):
                        params = .init(
                            title: L10n.somethingWentWrong,
                            description: response.message ?? L10n.unknownError
                        )
                    default:
                        break
                    }
                }
                self.openDetails.send(params)
            }
            .store(in: &subscriptions)
    }

    private func updateCompleted() {
        title = L10n.transactionSucceeded
        let text = L10n.theTransactionHasBeenSuccessfullyCompleted🤟
        state = .succeed(message: text)
        closeButtonTitle = L10n.done
    }

    private func update(error: Error?) {
        title = L10n.transactionFailed
        var text = L10n.theTransactionWasRejectedByTheSolanaBlockchain
        if let error = error as? NSError, error.isNetworkConnectionError {
            text = L10n.weCannotRetrieveTheTransactionStatusWithoutTheInternet
        }
        text = text.appending(" 🥺 ")
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
        closeButtonTitle = L10n.close
    }
}

extension SendTransactionStatusViewModel {
    enum State {
        case loading(message: String)
        case succeed(message: String)
        case error(message: NSAttributedString)
    }
}

private extension SendTransactionStatusViewModel {
    func logSend(event: KeyAppAnalyticsEvent, signature: String) {
        guard case let .sendNewConfirmButtonClick(
            sendFlow,
            token,
            max,
            amountToken,
            amountUSD,
            fee,
            fiatInput,
            _,
            pubKey
        ) = event else { return }
        analyticsManager.log(event: .sendNewConfirmButtonClick(
            sendFlow: sendFlow,
            token: token,
            max: max,
            amountToken: amountToken,
            amountUSD: amountUSD,
            fee: fee,
            fiatInput: fiatInput,
            signature: signature,
            pubKey: pubKey
        ))
    }
}
