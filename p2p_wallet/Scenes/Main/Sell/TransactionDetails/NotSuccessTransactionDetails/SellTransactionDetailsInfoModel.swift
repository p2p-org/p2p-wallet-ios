import Foundation
import SwiftUI
import UIKit

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
            iconColor = Color(.h9799Af)
            textColor = Color(.night)
            backgroundColor = Color(.e0E0E7)
            icon = .sellInfo
            let attributedText = NSMutableAttributedString(
                string: L10n.SOLWasSentToMoonpayAndIsBeingProcessed
                    .anyQuestionsRegardingYourTransactionCanBeAnsweredVia,
                attributes: Constants.textAttributes
            )
            attributedText.appending(NSMutableAttributedString(
                string: " \(L10n.moonpayHelpCenter)",
                attributes: Constants.helpAttributes
            ))
            text = .help(text: attributedText)

        case .fundsWereSent:
            iconColor = Color(.h9799Af)
            textColor = Color(.night)
            backgroundColor = Color(.e0E0E7)
            icon = .sellInfo
            let attributedText = NSMutableAttributedString(
                string: L10n.ItUsuallyTakesUpTo3BusinessDays.anyQuestionsRegardingYourTransactionCanBeAnsweredVia,
                attributes: Constants.textAttributes
            )
            attributedText.appending(NSMutableAttributedString(
                string: " \(L10n.moonpayHelpCenter)",
                attributes: Constants.helpAttributes
            ))
            text = .help(text: attributedText)

        case .youNeedToSend:
            iconColor = Color(.sun)
            textColor = Color(.night)
            backgroundColor = Color(.e0E0E7)
            icon = .sellPendingWarning
            text = .raw(text: L10n.youNeedToSendSOLToTheAddressInTheDescriptionToFinishYourCashOutOperation)

        case .youVeNotSent:
            iconColor = Color(.rose)
            textColor = Color(.rose)
            backgroundColor = Color(.rose).opacity(0.1)
            icon = .sellPendingWarning
            text = .raw(text: L10n
                .YouDidnTFinishYourCashOutTransaction
                .After7DaysYourTransactionHasBeenAutomaticallyDeclined
                .youCanTryAgainButYourNewTransactionWillBeSubjectToTheCurrentRates)
        }
    }
}

private enum Constants {
    static var textAttributes: [NSAttributedString.Key: Any] {
        [
            .font: UIFont.font(of: .text3),
            .foregroundColor: UIColor(resource: .night),
        ]
    }

    static var helpAttributes: [NSAttributedString.Key: Any] {
        [
            .font: UIFont.font(of: .text3),
            .foregroundColor: UIColor(resource: .sky),
        ]
    }
}
