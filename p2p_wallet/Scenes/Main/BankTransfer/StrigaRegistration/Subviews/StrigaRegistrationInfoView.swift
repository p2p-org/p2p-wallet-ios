import SwiftUI
import KeyAppUI

struct StrigaRegistrationInfoViewModel {
    static let credentials = BaseInformerViewItem(
        icon: .infoFill,
        iconColor: Asset.Colors.snow,
        title: .plain(L10n.EnterYourPersonalDataToOpenAnAccount.pleaseUseYourRealCredentials),
        backgroundColor: Asset.Colors.lightSea,
        iconBackgroundColor: Asset.Colors.sea
    )

    static let confirm = BaseInformerViewItem(
        icon: .shieldSmall,
        iconColor: Asset.Colors.night,
        title: .plain(L10n.afterClickingTheСontinueYouConfirmThatYouAreNotAPoliticallyExposedPerson),
        backgroundColor: Asset.Colors.rain,
        iconBackgroundColor: Asset.Colors.smoke
    )
}
