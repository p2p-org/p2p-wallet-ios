import AnalyticsManager
import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import UIKit

final class SendTransactionStatusViewModel: BaseViewModel, ObservableObject {
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var transactionHandler: TransactionHandler
    @Injected private var priceService: JupiterPriceService

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
            .map { [weak self] _ -> SendTransactionStatusDetailsParameters in
                guard let self = self,
                      let error = self.currentTransactionError
                else { return .unknown }

                if let error = error as? SendTransactionStatusViewableError,
                   let params = error.detail(feeAmount: feeAmount)
                {
                    return params
                }

                return .unknown
            }
            .sink { [weak self] params in
                self?.openDetails.send(params)
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
            .foregroundColor: UIColor(resource: .night),
        ])
        attributedError.appending(
            NSMutableAttributedString(string: buttonText, attributes: [
                .font: UIFont.font(of: .text4, weight: .bold),
                .foregroundColor: UIColor(resource: .rose),
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
