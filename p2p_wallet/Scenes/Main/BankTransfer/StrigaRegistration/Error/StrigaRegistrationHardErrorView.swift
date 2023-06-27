import KeyAppUI
import SwiftUI

struct StrigaRegistrationHardErrorView: View {
    let onAction: () -> Void
    let onSupport: () -> Void

    var body: some View {
        HardErrorView(
            title: L10n.seemsLikeThisNumberIsAlreadyUsed,
            subtitle: L10n.WithNewDataYouCanTUseStrigaServiceForNow.bouYouStillHaveBankCardAndCryptoOptions,
            image: .invest,
            content: {
                VStack(spacing: 12) {
                    NewTextButton(
                        title: L10n.openMyBlank,
                        style: .inverted,
                        expandable: true) {
                            onAction()
                        }
                    NewTextButton(
                        title: L10n.support,
                        style: .primary,
                        expandable: true) {
                            onSupport()
                        }
                }
            }
        )
    }
}

struct StrigaRegistrationHardErrorView_Previews: PreviewProvider {
    static var previews: some View {
        StrigaRegistrationHardErrorView(onAction: {}, onSupport: {})
    }
}
