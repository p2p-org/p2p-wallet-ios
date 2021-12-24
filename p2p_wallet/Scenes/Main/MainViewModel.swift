//
//  MainViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/06/2021.
//

import Foundation
import RxSwift
import RxCocoa
import LocalAuthentication

protocol MainViewModelType: AuthenticationHandler {
    var authenticationStatusDriver: Driver<AuthenticationPresentationStyle?> { get } // nil if non authentication process is processing
}

class MainViewModel {
    // MARK: - Dependencies
    @Injected private var socket: SolanaSDK.Socket
    @Injected private var pricesService: PricesServiceType
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private var timeRequiredForAuthentication = 10 // in seconds
    private var lastAuthenticationTimeStamp = 0
    private var isAuthenticationPaused = false
    
    // MARK: - Subjects
    private let authenticationStatusSubject = BehaviorRelay<AuthenticationPresentationStyle?>(value: nil)
    
    // MARK: - Initializer
    init() {
        bind()
        socket.connect()
        pricesService.startObserving()
    }
    
    deinit {
        socket.disconnect()
        pricesService.stopObserving()
    }
    
    /// Bind subjects
    private func bind() {
        authenticationStatusSubject
            .skip(while: { $0 == nil })
            .subscribe(onNext: { [weak self] status in
                if status == nil {
                    self?.lastAuthenticationTimeStamp = Int(Date().timeIntervalSince1970)
                }
            })
            .disposed(by: disposeBag)
        
        observeAppNotifications()
    }
    
    private func observeAppNotifications() {
        UIApplication.shared.rx.applicationDidBecomeActive
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                guard Int(Date().timeIntervalSince1970) >= self.lastAuthenticationTimeStamp + self.timeRequiredForAuthentication
                    else { return }
                self.authenticate(presentationStyle: .login())
            })
            .disposed(by: disposeBag)
    }
}

extension MainViewModel: MainViewModelType {
    func requiredOwner(onSuccess: (() -> Void)?, onFailure: ((String?) -> Void)?) {
        let myContext = LAContext()
        
        var error: NSError?
        guard myContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            DispatchQueue.main.async {
                onFailure?(errorToString(error))
            }
            return
        }
        
        myContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: L10n.confirmItSYou) { (success, error) in
            guard success else {
                DispatchQueue.main.async {
                    onFailure?(errorToString(error))
                }
                return
            }
            DispatchQueue.main.sync {
                onSuccess?()
            }
        }
    }
    
    var authenticationStatusDriver: Driver<AuthenticationPresentationStyle?> {
        authenticationStatusSubject.asDriver()
    }
    
    // MARK: - Authentication
    func authenticate(presentationStyle: AuthenticationPresentationStyle?) {
        // check previous and current
        let previous = self.authenticationStatusSubject.value
        let current = presentationStyle
        
        // prevent duplications
        guard (previous == nil && current != nil) || (previous != nil && current == nil)
            else { return }
        
        // accept current if nil
        if current == nil {
            authenticationStatusSubject.accept(nil)
            return
        }
        
        // show authentication if the condition has been met
        if canPerformAuthentication() {
            authenticationStatusSubject.accept(presentationStyle)
            return
        }
        
        // force a dissmision if not
        else {
            authenticationStatusSubject.accept(nil)
            return
        }
    }
    
    func pauseAuthentication(_ isPaused: Bool) {
        isAuthenticationPaused = isPaused
    }
    
    // MARK: - Helpers
    private func canPerformAuthentication() -> Bool {
        !isAuthenticationPaused
    }
}

private func errorToString(_ error: Error?) -> String? {
    var error = error?.localizedDescription ?? L10n.unknownError
    switch error {
    case "Passcode not set.":
        error = L10n.PasscodeNotSet.soWeCanTVerifyYouAsTheDeviceSOwner
    case "Canceled by user.":
        return nil
    default:
        break
    }
    return error
}
