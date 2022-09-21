import Combine
import Foundation
import KeyAppUI
import LocalAuthentication
import Resolver
import UIKit

enum PincodeState {
    case create
    case confirm(pin: String, askBiometric: Bool)
    case check
}

final class PincodeViewModel: BaseViewModel {
    // MARK: - Dependencies

    @Injected private var biometricsAuthProvider: BiometricsAuthProvider
    @Injected private var authenticationHandler: AuthenticationHandlerType
    @Injected private var pincodeService: PincodeService
    @Injected private var userWalletManager: UserWalletManager
    @Injected private var notificationService: NotificationService

    // MARK: - Properties

    @Published var title: String = ""
    @Published var snackbar: PincodeSnackbar?
    @Published var showAlert: (String, String)?
    @Published var showForgetPin: Bool = false
    @Published var showFaceid: Bool = false
    @Published var showForgotModal: Bool = false

    let back = PassthroughSubject<Void, Never>()
    let infoDidTap = PassthroughSubject<Void, Never>()
    let pincodeSuccess = PassthroughSubject<String?, Never>()
    let pincodeFailed = PassthroughSubject<Void, Never>()

    let confirmPin = PassthroughSubject<String, Never>()
    let openMain = PassthroughSubject<(String, Bool), Never>()

    let isBackAvailable: Bool
    // TODO: seems like it is used only in confirm state, move to case?
    let successNotification: String

    var pincode: String? {
        if case let .confirm(pin, _) = state { return pin }
        if case .check = state { return pincodeService.pincode() }
        return nil
    }

    private let state: PincodeState

    private var bioAuthStatus: LABiometryType {
        biometricsAuthProvider.availabilityStatus
    }

    // HACK: ignoreAuthHandler to ignore initial value
    init(
        state: PincodeState,
        isBackAvailable: Bool = true,
        successNotification: String,
        ignoreAuthHandler: Bool = false
    ) {
        self.state = state
        self.isBackAvailable = isBackAvailable
        self.successNotification = successNotification
        super.init()
        // Put fake value into authenticationStatusSubject. It is need for cancelling background/foreground lock logic in AuthenticationHandler.observeAppNotifications(). Might be refactored with AuthenticationHandler changes and enter pincode task
        if !ignoreAuthHandler {
            authenticationHandler.authenticate(presentationStyle: .init())
        }
        title = title(for: state)
        bind()

        switch state {
        case .check:
            showForgetPin = true
            showFaceid = false
            if Defaults.isBiometryEnabled, bioAuthStatus == .faceID || bioAuthStatus == .touchID {
                showFaceid = Defaults.isBiometryEnabled
                requestBiometrics { [weak self] succeed in
                    if succeed {
                        self?.pincodeService.resetAttempts()
                    }
                }
            }
        default:
            break
        }
    }

    // MARK: -

    func biometricsTapped() {
        requestBiometrics { [weak self] succeed in
            if succeed {
                self?.pincodeService.resetAttempts()
            }
        }
    }

    func requestBiometrics(onResult: ((Bool) -> Void)? = nil) {
        biometricsAuthProvider.authenticate(
            authenticationPrompt: L10n.enterPINCode, completion: { success, _ in
                onResult?(success)
                if success, let pin = self.pincodeService.pincode() {
                    self.authenticationHandler.authenticate(presentationStyle: nil)
                    self.openMain.send((pin, success))
                }
            }
        )
    }

    func forgotModalShowed() {
        showForgotModal.toggle()
    }

    func logout() {
        Task { try await self.userWalletManager.remove() }
    }
}

private extension PincodeViewModel {
    func title(for state: PincodeState) -> String {
        switch state {
        case .create:
            return L10n.createYourPasscode
        case .confirm:
            return L10n.confirmYourPasscode
        case .check:
            return L10n.enterYourPINCode
        }
    }

    func bind() {
        pincodeSuccess.sink { [weak self] value in
            guard let self = self, let pin = value else { return }
            switch self.state {
            case .create:
                self.confirmPin.send(pin)
            case let .confirm(_, askBiometric):
                self.snackbar = PincodeSnackbar(message: self.successNotification)
                if askBiometric {
                    self.biometricsAuthProvider.authenticate(
                        completion: { success, _ in
                            self.authenticationHandler.authenticate(presentationStyle: nil)
                            self.openMain.send((pin, success))
                        }
                    )
                } else {
                    self.openMain.send((pin, false))
                }
            case .check:
                self.pincodeService.resetAttempts()
                self.openMain.send((pin, false))
            }
        }.store(in: &subscriptions)

        pincodeFailed.eraseToAnyPublisher()
            .sink { [weak self] _ in
                guard let self = self else { return }
                switch self.state {
                case .create: break
                case .confirm:
                    self.snackbar = PincodeSnackbar(message: L10n.😢PasscodeDoesnTMatch.pleaseTryAgain)
                case .check:
                    do {
                        try self.pincodeService.pincodeFailed()
                    } catch {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.notificationService.showAlert(
                                title: L10n.youWereSignedOut,
                                text: L10n.after5IncorrectAppPINCodes
                            )
                        }
                        self.logout()
                    }
                    if self.pincodeService.attemptsLeft() == 2 {
                        self.showForgotModal = true
                    } else if self.pincodeService.attemptsLeft() == 0 {
                        // pass
                    } else {
                        self.snackbar = PincodeSnackbar(
                            title: "😢",
                            message: L10n.IncorrectPIN.tryAgain
                        )
                    }
                }
            }.store(in: &subscriptions)
    }
}
