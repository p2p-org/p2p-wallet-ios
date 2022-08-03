import Combine
import LocalAuthentication
import Resolver
import UIKit

extension PincodeViewModel {
    enum NavigatableScene {
        case confirm(pin: String)
        case openInfo
        case openMain(pin: String)
    }
}

final class PincodeViewModel: BaseViewModel {
    var bioAuthStatus: LABiometryType {
        biometricsAuthProvider.availabilityStatus
    }

    // MARK: - Dependencies

    @Injected private var pincodeStorage: PincodeStorageType
    @Injected private var biometricsAuthProvider: BiometricsAuthProvider

    // MARK: - Properties

    @Published var title: String = ""
    @Published var navigatableScene: NavigatableScene?
    @Published var snackbar: (image: UIImage, title: String)?

    let bioAuthDidTap = PassthroughSubject<Void, Never>()
    let infoDidTap = PassthroughSubject<Void, Never>()
    let pincodeSuccess = PassthroughSubject<String?, Never>()
    let pincodeFailed = PassthroughSubject<Void, Never>()
    let pincodeFailedAndExceededMaxAttempts = PassthroughSubject<Void, Never>()

    var pincode: String? {
        switch state {
        case .create:
            return nil
        case let .confirm(pin):
            return pin
        }
    }

    let isBiometryAvailable: Bool

    private let state: PincodeState

    init(state: PincodeState) {
        self.state = state
        if case .confirm = state {
            isBiometryAvailable = true
        } else {
            isBiometryAvailable = false
        }
        super.init()
        title = title(for: state)
        bind()
    }
}

private extension PincodeViewModel {
    func title(for state: PincodeState) -> String {
        switch state {
        case .create:
            return L10n.createYourPINCode
        case .confirm:
            return L10n.confirmYourPINCode
        }
    }

    func bind() {
        infoDidTap.sink { [weak self] _ in
            self?.navigatableScene = .openInfo
        }.store(in: &subscriptions)

        pincodeSuccess.sink { [weak self] value in
            guard let self = self, let pin = value else { return }
            switch self.state {
            case .create:
                self.navigatableScene = .confirm(pin: pin)
            case .confirm:
                self.snackbar = (image: .emojiVictoryHand, title: L10n.yeahYouVeCreatedThePINToKeyApp)
                self.navigatableScene = .openMain(pin: pin)
                self.pincodeStorage.save(pin)
            }
        }.store(in: &subscriptions)

        pincodeFailed.sink { [weak self] _ in
            guard let self = self else { return }
            switch self.state {
            case .create: break
            case .confirm:
                self.snackbar = (image: .emojiCryFace, title: L10n.PINDoesnTMatch.tryAgain)
            }
        }.store(in: &subscriptions)

        pincodeFailedAndExceededMaxAttempts.sink { _ in

        }.store(in: &subscriptions)

        bioAuthDidTap.sink { [weak self] _ in
            guard let self = self else { return }
            let prompt = L10n
                .insteadOfAPINCodeYouCanAccessTheAppUsing(self.bioAuthStatus.stringValue)
            self.biometricsAuthProvider.authenticate(
                authenticationPrompt: prompt, completion: { success in
                    debugPrint(success)
                }
            )
        }.store(in: &subscriptions)
    }
}
