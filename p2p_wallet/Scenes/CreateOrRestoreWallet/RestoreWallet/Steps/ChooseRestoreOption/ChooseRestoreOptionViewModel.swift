import Combine
import KeyAppUI
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
            default:
                break
            }

            let process = ReactiveProcess<RestoreOption>(data: option) { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    switch error {
                    case is SocialServiceError: break
                    default: self.notificationService.showDefaultErrorNotification()
                    }
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
}
