import AnalyticsManager
import Combine
import KeyAppUI
import Onboarding
import Resolver
import SwiftUI
import UIKit

final class ChooseRestoreOptionViewModel: BaseICloudRestoreViewModel {
    // MARK: - Dependencies

    @Injected private var biometricsProvider: BiometricsAuthProvider
    @Injected private var keychainStorage: KeychainStorage
    @Injected private var analyticsManager: AnalyticsManager

    // MARK: - Properties

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
    let restoreRawWallet = PassthroughSubject<ReactiveProcess<RawAccount>, Never>()

    let isBackAvailable: Bool
    let isStartAvailable: Bool

    var buttonsCount: Int {
        mainButtons.count + secondaryButtons.count + (isStartAvailable ? 1 : 0)
    }

    init(parameters: ChooseRestoreOptionParameters) {
        options = parameters.options
        data = parameters.content
        isBackAvailable = parameters.isBackAvailable
        isStartAvailable = parameters.isStartAvailable
        super.init()
        configureButtons(options: options)

        optionDidTap.sink { [weak self] option in
            guard let self = self else { return }
            self.log(option: option)

            switch option {
            case .socialGoogle, .socialApple:
                self.isLoading = option
            case .keychain:
                if let accounts = self.keychainStorage.accountFromICloud(), accounts.count == 1 {
                    self.restore(icloudAccount: accounts[0])
                    return
                }
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

    private func restore(icloudAccount: RawAccount) {
        isLoading = .keychain
        let process = ReactiveProcess<RawAccount>(data: icloudAccount) { [weak self] _ in
            self?.isLoading = nil
        }
        authenticate(completion: { [weak self] success in
            if success {
                self?.restoreRawWallet.send(process)
            } else {
                self?.isLoading = nil
            }
        })
    }

    private func log(option: RestoreOption) {
        analyticsManager.log(
            event: AmplitudeEvent.selectRestoreOption(
                restoreOption: option.analyticsRawValue,
                keychaineOption: options.contains(.keychain)
            )
        )
    }
}

private extension RestoreOption {
    var analyticsRawValue: String {
        switch self {
        case .seed:
            return "seed"
        case .keychain:
            return "keychaine"
        case .socialApple:
            return "apple"
        case .socialGoogle:
            return "google"
        case .custom:
            return "phone"
        default:
            return ""
        }
    }
}
