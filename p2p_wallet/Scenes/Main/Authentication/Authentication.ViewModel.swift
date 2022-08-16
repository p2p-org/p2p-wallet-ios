//
//  Authentication.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/11/2021.
//

import Combine
import Foundation
import LocalAuthentication
import Resolver

protocol AuthenticationViewModelType {
    var navigatableScenePublisher: AnyPublisher<Authentication.NavigatableScene?, Never> { get }
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
    class ViewModel: BaseViewModel {
        // MARK: - Dependencies

        @Injected private var pincodeStorage: PincodeStorageType
        @Injected private var logoutResponder: LogoutResponder

        // MARK: - Subject

        @Published private var navigatableScene: NavigatableScene?
    }
}

extension Authentication.ViewModel: AuthenticationViewModelType {
    var navigatableScenePublisher: AnyPublisher<Authentication.NavigatableScene?, Never> {
        $navigatableScene.eraseToAnyPublisher()
    }

    // MARK: - Actions

    func showResetPincodeWithASeedPhrase() {
        navigatableScene = .resetPincodeWithASeedPhrase
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
                print(error)
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
        setBlockedTime(nil)
        navigatableScene = .signOutAlert { [weak self] in self?.logoutResponder.logout() }
    }
}
