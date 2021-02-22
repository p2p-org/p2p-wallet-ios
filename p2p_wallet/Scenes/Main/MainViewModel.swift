//
//  MainViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/02/2021.
//

import UIKit
import RxSwift
import RxCocoa
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func observeAppNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidActive), name: UIScene.didActivateNotification, object: nil)
    }
    
    // MARK: - Application notifications
    @objc func appDidActive() {
        guard !isAuthenticating, isSessionExpired else {return}
        isAuthenticating = true
        authenticationSubject.onNext(())
    }
    
    func secondsLeftToNextAuthentication() -> Int {
        timeRequiredForAuthentication - (Int(Date().timeIntervalSince1970) - Int(lastAuthenticationTimestamp))
    }
}
