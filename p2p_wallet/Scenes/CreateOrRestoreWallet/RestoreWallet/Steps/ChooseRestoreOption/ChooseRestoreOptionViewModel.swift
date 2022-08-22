import Combine
import KeyAppUI
import SwiftUI
import UIKit

final class ChooseRestoreOptionViewModel: BaseViewModel {
    @Published var data: OnboardingContentData
    @Published var options: RestoreOption
    @Published var isLoading: RestoreOption?

    @Published var mainButtons: [ChooseRestoreOptionButton] = []
    @Published var secondaryButtons: [ChooseRestoreOptionButton] = []

    let back = PassthroughSubject<Void, Never>()
    let openInfo = PassthroughSubject<Void, Never>()
    let optionDidTap = PassthroughSubject<RestoreOption, Never>()
    let optionChosen = PassthroughSubject<ReactiveProcess<RestoreOption>, Never>()

    init(options: RestoreOption) {
        self.options = options
        data = OnboardingContentData(
            image: .lockPincode,
            title: L10n.chooseTheWayToContinue
        )
        super.init()
        configureButtons(options: options)

        optionDidTap.sink { [weak self] option in
            guard let self = self else { return }
            switch option {
            case .socialGoogle, .socialApple:
                self.isLoading = option
            default:
                break
            }

            let process = ReactiveProcess<RestoreOption>(data: option) { error in
                if let error = error {}
                self.isLoading = nil
            }

            self.optionChosen.send(process)

        }.store(in: &subscriptions)
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
