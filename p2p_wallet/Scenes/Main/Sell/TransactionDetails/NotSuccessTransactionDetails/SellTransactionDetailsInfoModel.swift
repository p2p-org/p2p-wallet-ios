import Foundation
import KeyAppUI
import UIKit

struct SellTransactionDetailsInfoModel {
    enum InfoText {
        case raw(text: String)
        case help(text: NSAttributedString)
    }

    let text: InfoText
    let icon: UIImage
    let iconColor: UIColor
    let textColor: UIColor
    let backgroundColor: UIColor

    init(strategy: SellTransactionDetailsViewModel.Strategy) {
        switch strategy {
        case .processing:
            iconColor = UIColor.h9799af
            textColor = Asset.Colors.night.color
            backgroundColor = UIColor.e0e0e7
            icon = .sellInfo
            let attributedText = NSMutableAttributedString(
                string: L10n.SOLWasSentToMoonpayAndIsBeingProcessed
                    .anyQuestionsRegardingYourTransactionCanBeAnsweredVia,
                attributes: Constants.textAttributes
            )
            attributedText
                .appending(NSMutableAttributedString(string: " \(L10n.moonpayHelpCenter)",
                                                     attributes: Constants.helpAttributes))
            text = .help(text: attributedText)

        case .fundsWereSent:
            iconColor = UIColor.h9799af
            textColor = Asset.Colors.night.color
            backgroundColor = UIColor.e0e0e7
            icon = .sellInfo
            let attributedText = NSMutableAttributedString(
                string: L10n.ItUsuallyTakesUpTo3BusinessDays.anyQuestionsRegardingYourTransactionCanBeAnsweredVia,
                attributes: Constants.textAttributes
            )
            attributedText
                .appending(NSMutableAttributedString(string: " \(L10n.moonpayHelpCenter)",
                                                     attributes: Constants.helpAttributes))
            text = .help(text: attributedText)

        case .youNeedToSend:
            iconColor = Asset.Colors.sun.color
            textColor = Asset.Colors.night.color
            backgroundColor = UIColor.e0e0e7
            icon = .sellPendingWarning
            text = .raw(text: L10n.youNeedToSendSOLToTheAddressInTheDescriptionToFinishYourCashOutOperation)

        case .youVeNotSent:
            iconColor = Asset.Colors.rose.color
            textColor = Asset.Colors.rose.color
            backgroundColor = Asset.Colors.rose.color.withAlphaComponent(0.1)
            icon = .sellPendingWarning
            text = .raw(text: L10n
                .YouDidnTFinishYourCashOutTransaction
                .After7DaysYourTransactionHasBeenAutomaticallyDeclined
                .youCanTryAgainButYourNewTransactionWillBeSubjectToTheCurrentRates)
        }
    }
}

private enum Constants {
    static let textAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.font(of: .text3),
                                                                .foregroundColor: Asset.Colors.night.color]
    static let helpAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.font(of: .text3),
                                                                .foregroundColor: Asset.Colors.sky.color]
}
