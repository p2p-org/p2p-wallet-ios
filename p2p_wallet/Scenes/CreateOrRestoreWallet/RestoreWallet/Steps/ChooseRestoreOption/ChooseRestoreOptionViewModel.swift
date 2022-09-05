import Combine
import KeyAppUI
import Onboarding
import Resolver
import SwiftUI
import UIKit

final class ChooseRestoreOptionViewModel: BaseViewModel {
    // MARK: - Dependencies

    @Injected var notificationService: NotificationService

    @Published var data: OnboardingContentData
    @Published var options: RestoreOption
    @Published var isLoading: RestoreOption?

    @Published var mainButtons: [ChooseRestoreOptionButton] = []
    @Published var secondaryButtons: [ChooseRestoreOptionButton] = []

    let back = PassthroughSubject<Void, Never>()
    let openStart = PassthroughSubject<Void, Never>()
    let openInfo = PassthroughSubject<Void, Never>()
    let optionDidTap = PassthroughSubject<RestoreOption, Never>()
    let optionChosen = PassthroughSubject<ReactiveProcess<RestoreOption>, Never>()

    let isBackAvailable: Bool
    let isStartAvailable: Bool

    init(parameters: ChooseRestoreOptionParameters) {
        options = parameters.options
        data = parameters.content
        isBackAvailable = parameters.isBackAvailable
        isStartAvailable = parameters.isStartAvailable
        super.init()
        configureButtons(options: options)

        optionDidTap.sink { [weak self] option in
            guard let self = self else { return }

            switch option {
            case .socialGoogle, .socialApple:
                self.isLoading = option
            default: break
            }

            self.notificationService.hideToasts()
            let process = ReactiveProcess<RestoreOption>(data: option) { error in
                if let error = error as? SocialServiceError {
                    switch error {
                    case .cancelled: break
                    default: self.showSocialError(provider: option == .socialGoogle ? .google : .apple)
                    }
                } else if error != nil {
                    self.notificationService.showDefaultErrorNotification()
                }
                self.isLoading = nil
            }

            self.optionChosen.send(process)

        }.store(in: &subscriptions)
    }

    private func configureButtons(options: RestoreOption) {
        let factory = ChooseRestoreOptionButtonFactory()

        if options.contains(.keychain) {
            mainButtons.append(factory.createMain(for: .keychain))
        }

        if options.contains(.socialApple) {
            mainButtons.append(factory.createMain(for: .socialApple))
        }

        if options.contains(.socialGoogle), !options.contains(.keychain) {
            mainButtons.append(factory.createMain(for: .socialGoogle))
        }

        if options.contains(.custom) {
            if mainButtons.isEmpty {
                mainButtons.append(factory.createMain(for: .custom))
            } else {
                secondaryButtons.append(factory.createSecondary(for: .custom))
            }
        }

        if options.contains(.socialGoogle), options.contains(.keychain) {
            secondaryButtons.append(factory.createSecondary(for: .socialGoogle))
        }

        if options.contains(.seed) {
            secondaryButtons.append(factory.createSecondary(for: .seed))
        }
    }

    private func showSocialError(provider: SocialProvider) {
        notificationService.showToast(
            title: nil,
            text: L10n.ThereIsAProblemWithServices.tryAgain(provider.rawValue.uppercaseFirst)
        )
    }
}
