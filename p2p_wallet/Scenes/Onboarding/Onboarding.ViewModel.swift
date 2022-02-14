//
//  Onboarding.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import UIKit
import RxSwift
import RxCocoa
import LocalAuthentication
import UserNotifications

protocol OnboardingHandler {
    func onboardingDidCancel()
    func onboardingDidComplete()
}

protocol OnboardingViewModelType {
    var navigatableSceneDriver: Driver<Onboarding.NavigatableScene?> {get}
    
    func savePincode(_ pincode: String)
    
    func getBiometryType() -> LABiometryType
    func authenticateAndEnableBiometry(errorHandler: ((Error) -> Void)?)
    func enableBiometryLater()
    
    func requestRemoteNotifications()
    func markNotificationsAsSet()
    
    func navigateNext()
    func cancelOnboarding()
    func endOnboarding()
}

extension Onboarding {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var handler: OnboardingHandler
        @Injected private var pinCodeStorage: PincodeStorageType
        @Injected private var analyticsManager: AnalyticsManagerType
        
        // MARK: - Properties
        private let bag = DisposeBag()
        private let context = LAContext()
        
        // MARK: - Subjects
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        
        // MARK: - Initializer
        init() {
            navigateNext()
        }
        
        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }
    }
}

extension Onboarding.ViewModel: OnboardingViewModelType {
    var navigatableSceneDriver: Driver<Onboarding.NavigatableScene?> {
        navigationSubject.asDriver()
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

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { (success, authenticationError) in

            DispatchQueue.main.async { [weak self] in
                if success {
                    self?.setEnableBiometry(true)
                } else {
                    errorHandler?(authenticationError ?? SolanaSDK.Error.unknown)
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
            analyticsManager.log(event: .bioApproved(lastScreen: "Onboarding"))
        } else {
            analyticsManager.log(event: .bioRejected)
        }
        
        navigateNext()
    }
    
    // MARK: - Notification
    func requestRemoteNotifications() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) {[weak self] granted, _ in
                print("Permission granted: \(granted)")
                DispatchQueue.main.async { [weak self] in
                    guard granted else {
                        UIApplication.shared.openAppSettings()
                        return
                    }
                    UIApplication.shared.registerForRemoteNotifications()
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
            navigationSubject.accept(.createPincode)
            return
        }
        
        if !Defaults.didSetEnableBiometry {
            var error: NSError?
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                // evaluate
                navigationSubject.accept(.setUpBiometryAuthentication)
                analyticsManager.log(event: .setupFaceidOpen)
            } else {
                enableBiometryLater()
            }
            
            if let error = error {
                debugPrint("deviceOwnerAuthenticationWithBiometrics error: \(error)")
            }
            return
        }
        
        if !Defaults.didSetEnableNotifications {
            UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
                debugPrint("Notification settings: \(settings)")
                
                guard let self = self else {return}
                
                // not authorized
                guard settings.authorizationStatus == .authorized else {
                    self.navigationSubject.accept(.setUpNotifications)
                    self.analyticsManager.log(event: .setupAllowPushOpen)
                    return
                }
                
                // authorized
                DispatchQueue.main.async { [weak self] in
                    UIApplication.shared.registerForRemoteNotifications()
                    self?.markNotificationsAsSet()
                }
            }
            return
        }
        
        endOnboarding()
    }
    
    func cancelOnboarding() {
        navigationSubject.accept(.dismiss)
        handler.onboardingDidCancel()
    }
    
    func endOnboarding() {
        navigationSubject.accept(.dismiss)
        handler.onboardingDidComplete()
    }
}
