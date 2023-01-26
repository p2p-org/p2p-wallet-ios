import KeyAppUI

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
            self.iconColor = UIColor._9799Af
            self.textColor = Asset.Colors.night.color
            self.backgroundColor = UIColor.e0E0E7
            self.icon = .sellInfo
            let attributedText = NSMutableAttributedString(string: L10n.SOLWasSentToMoonpayAndIsBeingProcessed.anyQuestionsRegardingYourTransactionCanBeAnsweredVia, attributes: Constants.textAttributes)
            attributedText.appending(NSMutableAttributedString(string: " \(L10n.moonpayHelpCenter)", attributes: Constants.helpAttributes))
            self.text = .help(text: attributedText)

        case .fundsWereSent:
            self.iconColor = UIColor._9799Af
            self.textColor = Asset.Colors.night.color
            self.backgroundColor = UIColor.e0E0E7
            self.icon = .sellInfo
            let attributedText = NSMutableAttributedString(string: L10n.ItUsuallyTakesUpTo3BusinessDays.anyQuestionsRegardingYourTransactionCanBeAnsweredVia, attributes: Constants.textAttributes)
            attributedText.appending(NSMutableAttributedString(string: " \(L10n.moonpayHelpCenter)", attributes: Constants.helpAttributes))
            self.text = .help(text: attributedText)

        case .youNeedToSend:
            self.iconColor = Asset.Colors.sun.color
            self.textColor = Asset.Colors.night.color
            self.backgroundColor = UIColor.e0E0E7
            self.icon = .sellPendingWarning
            self.text = .raw(text: L10n
                .ToFinishProcessingYourRequestYouNeedToSendSOLToTheAddressInTheDescription
                .after7DaysThisTransactionWillBeAutomaticallyDeclined
            )

        case .youVeNotSent:
            self.iconColor = Asset.Colors.rose.color
            self.textColor = Asset.Colors.rose.color
            self.backgroundColor = Asset.Colors.rose.color.withAlphaComponent(0.1)
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
    static let textAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.font(of: .text3),
                                                                    .foregroundColor: Asset.Colors.night.color]
    static let helpAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.font(of: .text3),
                                                                         .foregroundColor: Asset.Colors.sky.color]
}
