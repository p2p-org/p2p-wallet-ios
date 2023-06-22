import KeyAppUI
import BankTransfer
import SwiftUI

struct HomeBannerParameters {
    struct Button {
        let title: String
        let handler: () -> Void
    }

    let backgroundColor: UIColor
    let image: UIImage
    let imageSize: CGSize
    let title: String
    let subtitle: String?
    let button: Button?

    init(
        backgroundColor: UIColor,
        image: UIImage,
        imageSize: CGSize,
        title: String,
        subtitle: String?,
        button: Button?
    ) {
        self.title = title
        self.subtitle = subtitle
        self.button = button
        self.image = image
        self.imageSize = imageSize
        self.backgroundColor = backgroundColor
    }

    init(
        status: StrigaKYCStatus,
        action: @escaping () -> Void,
        isSmallBanner: Bool
    ) {
        switch status {
        case .notStarted, .initiated:
            backgroundColor = Asset.Colors.lightSea.color
            image = .kycFinish
            if isSmallBanner {
                imageSize = CGSize(width: 121, height: 91)
            } else {
                imageSize = CGSize(width: 153, height: 123)
            }
            if isSmallBanner {
                title = L10n.HomeSmallBanner.finishIdentityVerificationToSendMoneyWorldwide
            } else {
                title = L10n.finishIdentityVerificationToSendMoneyWorldwide
            }
            subtitle = nil
            self.button = Button(title: L10n.continue, handler: action)

        case .pendingReview, .onHold:
            backgroundColor = Asset.Colors.lightSea.color
            image = .kycClock
            if isSmallBanner {
                imageSize = CGSize(width: 100, height: 100)
            } else {
                imageSize = CGSize(width: 120, height: 117)
            }
            title = L10n.HomeBanner.yourDocumentsVerificationIsPending
            subtitle = L10n.usuallyItTakesAFewHours
            self.button = nil

        case .approved:
            backgroundColor = Asset.Colors.lightGrass.color
            image = .kycSend
            if isSmallBanner {
                imageSize = CGSize(width: 132, height: 117)
            } else {
                imageSize = CGSize(width: 132, height: 117)
            }
            title = L10n.verificationIsDone
            subtitle = L10n.continueYourTopUpViaABankTransfer
            self.button = Button(title: L10n.topUp, handler: action)

        case .rejected:
            backgroundColor = Asset.Colors.lightSun.color
            image = .kycShow
            if isSmallBanner {
                imageSize = CGSize(width: 115, height: 112)
            } else {
                imageSize = CGSize(width: 115, height: 112)
            }
            title = L10n.actionRequired
            subtitle = L10n.pleaseCheckTheDetailsAndUpdateYourData
            self.button = Button(title: L10n.checkDetails, handler: action)

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
            self.button = Button(title: L10n.seeDetails, handler: action)

        }
    }
}

extension HomeBannerParameters: Equatable {
    static func == (lhs: HomeBannerParameters, rhs: HomeBannerParameters) -> Bool {
        return lhs.title == rhs.title && lhs.button?.title == rhs.button?.title && lhs.backgroundColor == rhs.backgroundColor && lhs.image == rhs.image && lhs.imageSize == rhs.imageSize && lhs.subtitle == rhs.subtitle
    }
}
