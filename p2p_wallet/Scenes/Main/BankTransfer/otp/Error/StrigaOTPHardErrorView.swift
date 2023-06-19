import Foundation
import KeyAppUI
import SwiftUI

struct StrigaOTPHardErrorView: View {
    let title: String
    let subtitle: String
    let onAction: () -> Void
    let onSupport: () -> Void

    var body: some View {
        HardErrorView(
            title: title,
            subtitle: subtitle,
            content: {
                VStack(spacing: 30) {
                    NewTextButton(
                        title: L10n.openWalletScreen,
                        style: .inverted) {
                            onAction()
                        }
                    NewTextButton(
                        title: L10n.writeToSuppot,
                        style: .primaryWhite) {
                            onSupport()
                        }
                }
            }
        )
    }
}

struct StrigaOTPHardErrorView_Previews: PreviewProvider {
    static var previews: some View {
        StrigaOTPHardErrorView(
            title: L10n.pleaseWait1DayForTheNextTry,
            subtitle: L10n.after5SMSRequestsWeDisabledItFor1DayToSecureYourAccount,
            onAction: {}, onSupport: {})
    }
}