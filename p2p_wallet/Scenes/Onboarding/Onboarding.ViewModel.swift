//
//  Onboarding.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import UIKit
import RxSwift
import RxCocoa

protocol OnboardingHandler {
    func onboardingDidCancel()
    func onboardingDidComplete()
}

protocol OnboardingViewModelType {
    var navigatableSceneDriver: Driver<Onboarding.NavigatableScene?> {get}
    
    func navigateNext()
    func savePincode(_ pincode: String)
    func setEnableBiometry(_ on: Bool)
    func markNotificationsAsSet()
    func cancelOnboarding()
    func endOnboarding()
}

extension Onboarding {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var handler: OnboardingHandler
        @Injected private var accountStorage: KeychainAccountStorage
        @Injected private var analyticsManager: AnalyticsManagerType
        
        // MARK: - Properties
        private let bag = DisposeBag()
        
        // MARK: - Subjects
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        
        // MARK: - Initializer
        init() {
            navigateNext()
        }
    }
}

extension Onboarding.ViewModel: OnboardingViewModelType {
    var navigatableSceneDriver: Driver<Onboarding.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    // MARK: - Binding
    func navigateNext() {
        if accountStorage.pinCode == nil {
            navigationSubject.accept(.createPincode)
        } else if !Defaults.didSetEnableBiometry {
            navigationSubject.accept(.setUpBiometryAuthentication)
        } else {
            navigationSubject.accept(.setUpNotifications)
        }
    }
    
    // MARK: - Actions
    func savePincode(_ pincode: String) {
        accountStorage.save(pincode)
        navigationSubject.accept(.setUpBiometryAuthentication)
    }
    
    func setEnableBiometry(_ on: Bool) {
        Defaults.isBiometryEnabled = on
        Defaults.didSetEnableBiometry = true
        analyticsManager.log(event: .setupFaceidClick(faceID: on))
        
        navigationSubject.accept(.setUpNotifications)
    }
    
    func markNotificationsAsSet() {
        Defaults.didSetEnableNotifications = true
        endOnboarding()
    }
    
    @objc func cancelOnboarding() {
        navigationSubject.accept(.dismiss)
        handler.onboardingDidCancel()
    }
    
    func endOnboarding() {
        navigationSubject.accept(.dismiss)
        handler.onboardingDidComplete()
    }
}
