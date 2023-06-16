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
                        style: .inverted) {
                            onAction()
                        }
                    NewTextButton(
                        title: L10n.support,
                        style: .primary) {
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
