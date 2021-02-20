//
//  OnboardingViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import UIKit
import RxSwift
import RxCocoa

enum OnboardingNavigatableScene {
    case createPincode
    case setUpBiometryAuthentication
    case setUpNotifications
}

class OnboardingViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let bag = DisposeBag()
    let handler: OnboardingHandler
    let accountStorage: KeychainAccountStorage
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<OnboardingNavigatableScene>()
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Initializer
    init(accountStorage: KeychainAccountStorage, handler: OnboardingHandler) {
        self.accountStorage = accountStorage
        self.handler = handler
        navigateNext()
    }
    
    // MARK: - Binding
    func navigateNext() {
        if accountStorage.pinCode == nil {
            navigationSubject.onNext(.createPincode)
        } else if !Defaults.didSetEnableBiometry {
            navigationSubject.onNext(.setUpBiometryAuthentication)
        } else if !Defaults.didSetEnableNotifications {
            navigationSubject.onNext(.setUpNotifications)
        }
    }
    
    // MARK: - Actions
//    @objc func showDetail() {
//        
//    }
}
