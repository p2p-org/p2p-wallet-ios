import Foundation
import SolanaSwift
import KeyAppUI

class SendTransactionStatusViewModel: ObservableObject {
    var token: Token = .nativeSolana
    @Published var title: String = "Transaction submitted"
    @Published var subtitle: String = "August 22, 2022 @ 08:08"
    @Published var transactionFiatAmount: String = "-$10"
    @Published var transactionCryptoAmount: String = "0.622 SOL"
    @Published var info = [(title: String, detail: String)]()
    @Published var state: State = .loading(message: L10n.itUsuallyTakes520SecondsForATransactionToComplete)

    func done() {
        // Coordinator call to close
    }

    init() {
        info = [
            (title: "Sent to", detail: "@kirill.key"),
            (title: "Transaction Fee", detail: "Fee (Paid by Key App)"),
        ]

        /// Uncomment for Error state
        /*
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
         */

        // Uncomment for Success state
        /*
        let text = L10n.theTransactionHasBeenSuccessfullyCompleted🤟
        self.state = .succeed(message: text)
         */
    }
}

extension SendTransactionStatusViewModel {
    enum State {
        case loading(message: String)
        case succeed(message: String)
        case error(message: NSAttributedString)
    }
}
