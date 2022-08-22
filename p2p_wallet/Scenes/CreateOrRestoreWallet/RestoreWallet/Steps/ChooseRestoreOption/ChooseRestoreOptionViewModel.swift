import Combine
import KeyAppUI
import SwiftUI
import UIKit

final class ChooseRestoreOptionViewModel: BaseViewModel {
    @Published var data: OnboardingContentData
    @Published var options: RestoreOption

    @Published var mainButtons: [ChooseRestoreOptionButton] = []
    @Published var secondaryButtons: [ChooseRestoreOptionButton] = []

    let optionChosen = PassthroughSubject<RestoreOption, Never>()

    init(options: RestoreOption) {
        self.options = options
        data = OnboardingContentData(
            image: .lockPincode,
            title: L10n.chooseTheWayToContinue
        )
        super.init()
        configureButtons(options: options)
    }

    private func configureButtons(options: RestoreOption) {
        if options.contains(.keychain) {
            mainButtons
                .append(ChooseRestoreOptionButton(option: .keychain, title: L10n.continueWithICloudKeyChain,
                                                  icon: UIImage.cloud))
        }

        if options.contains(.socialApple) {
            mainButtons.append(ChooseRestoreOptionButton(
                option: .socialApple,
                title: L10n.continueWithApple,
                icon: UIImage.appleLogo
            ))
        }

        if options.contains(.socialGoogle) {
            if options.contains(.keychain) {
                secondaryButtons
                    .append(ChooseRestoreOptionButton(option: .socialGoogle, title: L10n.continueUsingGoogle))
            } else {
                mainButtons
                    .append(ChooseRestoreOptionButton(option: .socialGoogle, title: L10n.continueWithGoogle,
                                                      icon: UIImage.google))
            }
        }

        if options.contains(.custom) {
            secondaryButtons.append(ChooseRestoreOptionButton(option: .custom, title: L10n.continueUsingPhoneNumber))
        }

        if options.contains(.seed) {
            secondaryButtons.append(ChooseRestoreOptionButton(option: .seed, title: L10n.useASeedPhrasePrivateKey))
        }
    }
}
