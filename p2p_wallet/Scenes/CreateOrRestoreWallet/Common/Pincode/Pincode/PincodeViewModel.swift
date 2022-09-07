import Combine
import KeyAppUI
import LocalAuthentication
import Resolver
import UIKit

enum PincodeState {
    case create
    case confirm(pin: String, askBiometric: Bool)
}

final class PincodeViewModel: BaseViewModel {
    // MARK: - Dependencies

    @Injected private var biometricsAuthProvider: BiometricsAuthProvider

    // MARK: - Properties

    @Published var title: String = ""
    @Published var snackbar: PincodeSnackbar?

    let back = PassthroughSubject<Void, Never>()
    let infoDidTap = PassthroughSubject<Void, Never>()
    let pincodeSuccess = PassthroughSubject<String?, Never>()
    let pincodeFailed = PassthroughSubject<Void, Never>()

    let confirmPin = PassthroughSubject<String, Never>()
    let openMain = PassthroughSubject<(String, Bool), Never>()

    let isBackAvailable: Bool
    let successNotification: String

    var pincode: String? {
        if case let .confirm(pin, _) = state { return pin }
        return nil
    }

    private let state: PincodeState

    private var bioAuthStatus: LABiometryType {
        biometricsAuthProvider.availabilityStatus
    }

    init(state: PincodeState, isBackAvailable: Bool = true, successNotification: String) {
        self.state = state
        self.isBackAvailable = isBackAvailable
        self.successNotification = successNotification
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
        pincodeSuccess.sink { [weak self] value in
            guard let self = self, let pin = value else { return }
            switch self.state {
            case .create:
                self.confirmPin.send(pin)
            case let .confirm(_, askBiometric):
                self.snackbar = PincodeSnackbar(message: self.successNotification, isFailure: false)
                let prompt = L10n
                    .insteadOfAPINCodeYouCanAccessTheAppUsing(self.bioAuthStatus.stringValue)

                if askBiometric {
                    self.biometricsAuthProvider.authenticate(
                        authenticationPrompt: prompt, completion: { success, _ in
                            self.openMain.send((pin, success))
                        }
                    )
                } else {
                    self.openMain.send((pin, false))
                }
            }
        }.store(in: &subscriptions)

        pincodeFailed.sink { [weak self] _ in
            guard let self = self else { return }
            switch self.state {
            case .create: break
            case .confirm:
                self.snackbar = PincodeSnackbar(message: L10n.😢PINDoesnTMatch.tryAgain, isFailure: true)
            }
        }.store(in: &subscriptions)
    }
}
