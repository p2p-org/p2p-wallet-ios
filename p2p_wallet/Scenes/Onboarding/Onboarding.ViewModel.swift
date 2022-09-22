//
//  Onboarding.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import AnalyticsManager
import Combine
import LocalAuthentication
import Resolver
import SolanaSwift
import UIKit
import UserNotifications

protocol OnboardingHandler {
    func onboardingDidCancel()
    func onboardingDidComplete()
}

protocol OnboardingViewModelType {
    var navigatableScenePublisher: AnyPublisher<Onboarding.NavigatableScene?, Never> { get }

    func savePincode(_ pincode: String)

    func getBiometryType() -> LABiometryType
    func authenticateAndEnableBiometry(errorHandler: ((Error) -> Void)?)
    func enableBiometryLater()

    func requestRemoteNotifications()
    func markNotificationsAsSet()

    func navigateNext()
    func cancelOnboarding()
}

extension Onboarding {
    class ViewModel: BaseViewModel {
        // MARK: - Dependencies

        @Injected private var handler: OnboardingHandler
        @Injected private var pinCodeStorage: PincodeStorageType
        @Injected private var analyticsManager: AnalyticsManager
        @Injected private var notificationService: NotificationService

        // MARK: - Properties

        private let context = LAContext()

        // MARK: - Subjects

        @Published private var navigatableScene: NavigatableScene?

        // MARK: - Initializer

        override init() {
            super.init()
            navigateNext()
        }
    }
}

extension Onboarding.ViewModel: OnboardingViewModelType {
    var navigatableScenePublisher: AnyPublisher<Onboarding.NavigatableScene?, Never> {
        $navigatableScene.eraseToAnyPublisher()
    }

    // MARK: - Pincode

    func savePincode(_ pincode: String) {
        pinCodeStorage.save(pincode)
        navigateNext()
    }

    // MARK: - Biometry

    func getBiometryType() -> LABiometryType {
        context.biometryType
    }

    func authenticateAndEnableBiometry(errorHandler: ((Error) -> Void)? = nil) {
        let reason = L10n.identifyYourself

        context
            .evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                            localizedReason: reason)
            { success, authenticationError in

                DispatchQueue.main.async { [weak self] in
                    if success {
                        self?.setEnableBiometry(true)
                    } else {
                        errorHandler?(authenticationError ?? SolanaError.unknown)
                        self?.enableBiometryLater()
                    }
                }
            }
    }

    func enableBiometryLater() {
        setEnableBiometry(false)
    }

    private func setEnableBiometry(_ on: Bool) {
        Defaults.isBiometryEnabled = on
        Defaults.didSetEnableBiometry = true
        if on {
            analyticsManager.log(event: AmplitudeEvent.bioApproved(lastScreen: "Onboarding"))
        } else {
            analyticsManager.log(event: AmplitudeEvent.bioRejected)
        }

        navigateNext()
    }

    // MARK: - Notification

    func requestRemoteNotifications() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
                print("Permission granted: \(granted)")
                DispatchQueue.main.async { [weak self] in
                    guard granted else {
                        UIApplication.shared.openAppSettings()
                        return
                    }
                    self?.notificationService.registerForRemoteNotifications()
                    self?.markNotificationsAsSet()
                }
            }
    }

    func markNotificationsAsSet() {
        Defaults.didSetEnableNotifications = true
        navigateNext()
    }

    // MARK: - Navigation

    func navigateNext() {
        if pinCodeStorage.pinCode == nil {
            navigatableScene = .createPincode
            return
        }

        if !Defaults.didSetEnableBiometry {
            var error: NSError?
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                // evaluate
                navigatableScene = .setUpBiometryAuthentication
                analyticsManager.log(event: AmplitudeEvent.setupFaceidOpen)
            } else {
                enableBiometryLater()
            }

            if let error = error {
                print("deviceOwnerAuthenticationWithBiometrics error: \(error)")
            }
            return
        }

        if !Defaults.didSetEnableNotifications {
            Task {
                let settings = await UNUserNotificationCenter.current().notificationSettings()
                print("Notification settings: \(settings)")

                // not authorized
                guard settings.authorizationStatus == .authorized else {
                    navigatableScene = .setUpNotifications
                    analyticsManager.log(event: AmplitudeEvent.setupAllowPushOpen)
                    return
                }

                // authorized
                notificationService.registerForRemoteNotifications()
                markNotificationsAsSet()
            }
            return
        }

        endOnboarding()
    }

    func cancelOnboarding() {
        navigatableScene = .dismiss
        handler.onboardingDidCancel()
    }

    func endOnboarding() {
        switch OnboardingTracking.currentFlow {
        case .create:
            analyticsManager.log(event: AmplitudeEvent.walletCreated(
                lastScreen: navigatableScene?.screenName ?? "Sign_In_Apple"
            ))
        case .restore:
            analyticsManager.log(event: AmplitudeEvent.walletRestored(
                lastScreen: navigatableScene?.screenName ?? "Sign_In_Apple"
            ))
        case .none:
            break
        }

        navigatableScene = .dismiss
        handler.onboardingDidComplete()
    }
}
