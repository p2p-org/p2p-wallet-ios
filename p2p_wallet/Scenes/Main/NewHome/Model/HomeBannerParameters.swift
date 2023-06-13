import KeyAppUI
import BankTransfer
import SwiftUI

struct HomeBannerParameters {
    let backgroundColor: UIColor
    let image: UIImage
    let imageSize: CGSize
    let title: String
    let subtitle: String?
    let actionTitle: String
    let action: () -> Void

    init(
        backgroundColor: UIColor,
        image: UIImage,
        imageSize: CGSize,
        title: String,
        subtitle: String?,
        actionTitle: String,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.image = image
        self.imageSize = imageSize
        self.backgroundColor = backgroundColor
        self.action = action
    }

    init(
        status: StrigaKYC.Status,
        action: @escaping () -> Void,
        isSmallBanner: Bool
    ) {
        self.action = action

        switch status {
        case .notStarted, .initiated:
            backgroundColor = Asset.Colors.lightSea.color
            image = .startThree
            if isSmallBanner {
                imageSize = CGSize(width: 120, height: 90)
            } else {
                imageSize = CGSize(width: 164, height: 123)
            }
            if isSmallBanner {
                title = L10n.HomeSmallBanner.finishIdentityVerificationToSendMoneyWorldwide
            } else {
                title = L10n.finishIdentityVerificationToSendMoneyWorldwide
            }
            subtitle = nil
            actionTitle = L10n.continue

        case .pendingReview, .onHold:
            backgroundColor = Asset.Colors.lightSea.color
            image = .kycClock
            if isSmallBanner {
                imageSize = CGSize(width: 100, height: 100)
            } else {
                imageSize = CGSize(width: 110, height: 107)
            }
            title = L10n.HomeBanner.yourDocumentsVerificationIsPending
            subtitle = L10n.usuallyItTakesAFewHours
            actionTitle = L10n.view
        case .approved:
            backgroundColor = Asset.Colors.lightGrass.color
            image = .kycSend
            if isSmallBanner {
                imageSize = CGSize(width: 160, height: 110)
            } else {
                imageSize = CGSize(width: 171, height: 125)
            }
            title = L10n.verificationIsDone
            subtitle = L10n.continueYourTopUpViaABankTransfer
            actionTitle = L10n.topUp
        case .rejected:
            backgroundColor = Asset.Colors.lightSun.color
            image = .kycShow
            if isSmallBanner {
                imageSize = CGSize(width: 150, height: 112)
            } else {
                imageSize = CGSize(width: 161, height: 115)
            }
            title = L10n.actionRequired
            subtitle = L10n.pleaseCheckTheDetailsAndUpdateYourData
            actionTitle = L10n.checkDetails
        case .rejectedFinal:
            backgroundColor = Asset.Colors.lightRose.color
            image = .kycFail
            if isSmallBanner {
                imageSize = CGSize(width: 126, height: 87)
            } else {
                imageSize = CGSize(width: 169, height: 111)
            }
            title = L10n.verificationIsRejected
            subtitle = L10n.addMoneyViaBankTransferIsUnavailable
            actionTitle = L10n.seeDetails
        }
    }
}
