import KeyAppUI
import SwiftUI
import Foundation

struct SellTransactionDetailsInfoModel {
    enum InfoText {
        case raw(text: String)
        case help(text: NSAttributedString)
    }

    let text: InfoText
    let icon: ImageResource
    let iconColor: Color
    let textColor: Color
    let backgroundColor: Color

    init(strategy: SellTransactionDetailsViewModel.Strategy) {
        switch strategy {
        case .processing:
            self.iconColor = Color(.h9799Af)
            self.textColor = Color(.night)
            self.backgroundColor = Color(.e0E0E7)
            self.icon = .sellInfo
            let attributedText = NSMutableAttributedString(string: L10n.SOLWasSentToMoonpayAndIsBeingProcessed.anyQuestionsRegardingYourTransactionCanBeAnsweredVia, attributes: Constants.textAttributes)
            attributedText.appending(NSMutableAttributedString(string: " \(L10n.moonpayHelpCenter)", attributes: Constants.helpAttributes))
            self.text = .help(text: attributedText)

        case .fundsWereSent:
            self.iconColor = Color(.h9799Af)
            self.textColor = Color(.night)
            self.backgroundColor = Color(.e0E0E7)
            self.icon = .sellInfo
            let attributedText = NSMutableAttributedString(string: L10n.ItUsuallyTakesUpTo3BusinessDays.anyQuestionsRegardingYourTransactionCanBeAnsweredVia, attributes: Constants.textAttributes)
            attributedText.appending(NSMutableAttributedString(string: " \(L10n.moonpayHelpCenter)", attributes: Constants.helpAttributes))
            self.text = .help(text: attributedText)

        case .youNeedToSend:
            self.iconColor = Color(.sun)
            self.textColor = Color(.night)
            self.backgroundColor = Color(.e0E0E7)
            self.icon = .sellPendingWarning
            self.text = .raw(text: L10n.youNeedToSendSOLToTheAddressInTheDescriptionToFinishYourCashOutOperation)

        case .youVeNotSent:
            self.iconColor = Color(.rose)
            self.textColor = Color(.rose)
            self.backgroundColor = Color(.rose).opacity(0.1)
            self.icon = .sellPendingWarning
            self.text = .raw(text: L10n
                .YouDidnTFinishYourCashOutTransaction
                .After7DaysYourTransactionHasBeenAutomaticallyDeclined
                .youCanTryAgainButYourNewTransactionWillBeSubjectToTheCurrentRates
            )

        }
    }
}

private enum Constants {
    static var textAttributes: [NSAttributedString.Key: Any] {
        [
            .font: UIFont.font(of: .text3),
            .foregroundColor: UIColor(resource: .night)
        ]
    }
    
    static var helpAttributes: [NSAttributedString.Key: Any] {
        [
            .font: UIFont.font(of: .text3),
            .foregroundColor: UIColor(resource: .sky)
        ]
    }
}
