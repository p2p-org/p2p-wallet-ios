import KeyAppUI
import BankTransfer
import SwiftUI

struct KYCBannerParameters {
    let title: String
    let subtitle: String?
    let actionTitle: String
    let image: UIImage
    let backgroundColor: Color

    init(status: StrigaKYC.Status) {
        switch status {
        case .notStarted, .initiated:
            title = L10n.finishIdentityVerificationToSendYourMoneyWorldwide
            subtitle = nil
            actionTitle = L10n.continue
            image = .startThree
            backgroundColor = Color(asset: Asset.Colors.lightSea)
        case .pendingReview, .onHold:
            title = L10n.yourDocumentsVerificationIsPending
            subtitle = L10n.usuallyItTakesAFewHours
            actionTitle = L10n.view
            image = .kycClock
            backgroundColor = Color(asset: Asset.Colors.lightSea)
        case .approved:
            title = L10n.verificationIsDone
            subtitle = L10n.continueYourTopUpViaABankTransfer
            actionTitle = L10n.topUp
            image = .kycSend
            backgroundColor = Color(asset: Asset.Colors.lightGrass)
        case .rejected:
            title = L10n.actionRequired
            subtitle = L10n.pleaseCheckTheDetailsAndUpdateYourData
            actionTitle = L10n.checkDetails
            image = .kycShow
            backgroundColor = Color(asset: Asset.Colors.lightSun)
        case .rejectedFinal:
            title = L10n.sorryBankTransferIsUnavailableForYou
            subtitle = nil
            actionTitle = L10n.seeDetails
            image = .kycFail
            backgroundColor = Color(asset: Asset.Colors.lightRose)
        }
    }
}
