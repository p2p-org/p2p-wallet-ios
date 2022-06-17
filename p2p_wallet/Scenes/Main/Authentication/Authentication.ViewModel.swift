//
//  Authentication.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/11/2021.
//

import Foundation
import LocalAuthentication
import Resolver
import RxCocoa
import RxSwift

protocol AuthenticationViewModelType {
    var navigationDriver: Driver<Authentication.NavigatableScene?> { get }
    func showResetPincodeWithASeedPhrase()
    func getCurrentPincode() -> String?
    func getCurrentBiometryType() -> LABiometryType
    func isBiometryEnabled() -> Bool
    func authWithBiometry(onSuccess: (() -> Void)?, onFailure: (() -> Void)?)
    func getBlockedTime() -> Date?
    func setBlockedTime(_ time: Date?)
    func signOut()
}

extension Authentication {
    class ViewModel {
        // MARK: - Dependencies

        @Injected private var pincodeStorage: PincodeStorageType
        @Injected private var logoutResponder: LogoutResponder

        // MARK: - Initializers

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }

        // MARK: - Subject

        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
    }
}

extension Authentication.ViewModel: AuthenticationViewModelType {
    var navigationDriver: Driver<Authentication.NavigatableScene?> {
        navigationSubject.asDriver()
    }

    // MARK: - Actions

    func showResetPincodeWithASeedPhrase() {
        navigationSubject.accept(.resetPincodeWithASeedPhrase)
    }

    func getCurrentPincode() -> String? {
        pincodeStorage.pinCode
    }

    func getCurrentBiometryType() -> LABiometryType {
        LABiometryType.current
    }

    func isBiometryEnabled() -> Bool {
        Defaults.isBiometryEnabled
    }

    func authWithBiometry(onSuccess: (() -> Void)?, onFailure: (() -> Void)?) {
        let myContext = LAContext()
        var authError: NSError?
        if myContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            if let error = authError {
                debugPrint(error)
                return
            }
            myContext
                .evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                localizedReason: L10n.confirmItSYou)
                { success, _ in
                    guard success else { return }
                    DispatchQueue.main.sync {
                        onSuccess?()
                    }
                }
        } else {
            onFailure?()
        }
    }

    func getBlockedTime() -> Date? {
        Defaults.authenticationBlockingTime
    }

    func setBlockedTime(_ time: Date?) {
        Defaults.authenticationBlockingTime = time
    }

    func signOut() {
        navigationSubject.accept(.signOutAlert { [weak self] in self?.logoutResponder.logout() })
    }
}
