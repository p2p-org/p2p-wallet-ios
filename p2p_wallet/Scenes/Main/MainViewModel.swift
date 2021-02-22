//
//  MainViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/02/2021.
//

import UIKit
import RxSwift
import RxCocoa
import RxAppState

class MainViewModel {
    // MARK: - Constants
    private let timeRequiredForAuthentication = 10 // in seconds
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    var isAuthenticating = false
    var lastAuthenticationTimestamp = Date().timeIntervalSince1970
    
    var isSessionExpired: Bool {
        Int(Date().timeIntervalSince1970) >= Int(lastAuthenticationTimestamp) + timeRequiredForAuthentication
    }
    
    // MARK: - Subject
    let authenticationSubject = PublishSubject<Void>()
    
    init() {
        defer {observeAppNotifications()}
    }
    
    func observeAppNotifications() {
        UIApplication.shared.rx.applicationDidBecomeActive
            .subscribe(onNext: {[weak self] _ in
                guard let strongSelf = self, !strongSelf.isAuthenticating, strongSelf.isSessionExpired else {return}
                strongSelf.isAuthenticating = true
                strongSelf.authenticationSubject.onNext(())
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Application notifications
    func secondsLeftToNextAuthentication() -> Int {
        timeRequiredForAuthentication - (Int(Date().timeIntervalSince1970) - Int(lastAuthenticationTimestamp))
    }
}
