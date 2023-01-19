//
//  TabBarViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 20.11.2022.
//

import Foundation
import NameService
import RenVMSwift
import Resolver
import RxCocoa
import RxSwift
import SolanaSwift

final class TabBarViewModel {
    // Dependencies
    @Injected private var socket: Socket
    @Injected private var pricesService: PricesServiceType
    @Injected private var lockAndMint: LockAndMintService
    @Injected private var burnAndRelease: BurnAndReleaseService
    @Injected private var authenticationHandler: AuthenticationHandlerType
    @Injected private var notificationService: NotificationService

    @Injected private var accountStorage: AccountStorageType
    @Injected private var nameService: NameService
    @Injected private var nameStorage: NameStorageType

    private let transactionAnalytics = [
        Resolver.resolve(SwapTransactionAnalytics.self),
    ]

    // Input
    let viewDidLoad = PublishRelay<Void>()

    init() {
        if #available(iOS 15.0, *) {
            socket.connect()
        }
        pricesService.startObserving()
        burnAndRelease.resume()

        // RenBTC service
        Task {
            try await lockAndMint.resume()
        }

        // Name service
        Task {
            guard let account = accountStorage.account else { return }
            let name: String = try await nameService.getName(account.publicKey.base58EncodedString) ?? ""
            nameStorage.save(name: name)
        }

        // Notification
        notificationService.requestRemoteNotificationPermission()
    }

    deinit {
        socket.disconnect()
        pricesService.stopObserving()
        debugPrint("\(String(describing: self)) deinited")
    }

    func authenticate(presentationStyle: AuthenticationPresentationStyle?) {
        authenticationHandler.authenticate(presentationStyle: presentationStyle)
    }
}

// MARK: - Output

extension TabBarViewModel {
    var authenticationStatusDriver: Driver<AuthenticationPresentationStyle?> {
        authenticationHandler.authenticationStatusDriver
    }

    var moveToHistory: Driver<Void> {
        Observable.merge(
            notificationService.showNotification
                .filter { $0 == .history }
                .mapToVoid(),
            viewDidLoad
                .filter { [weak self] in
                    self?.notificationService.showFromLaunch == true
                }
                .do(onNext: { [weak self] _ in
                    self?.notificationService.notificationWasOpened()
                })
        )
        .mapToVoid()
        .asDriver()
    }

    var moveToIntercomSurvey: Driver<String> {
        Observable.merge(
            authenticationHandler
                .isLockedDriver
                .asObservable()
                .filter { value in
                    GlobalAppState.shared.surveyID != nil && value == false
                }
                .mapToVoid(),

            viewDidLoad
                .filter { [weak self] in
                    self?.notificationService.showFromLaunch == true
                }
        )
        .mapToVoid()
        .map {
            GlobalAppState.shared.surveyID ?? ""
        }
        .do(onNext: { _ in
            GlobalAppState.shared.surveyID = nil
        })
        .asDriver()
    }

    var isLockedDriver: Driver<Bool> { authenticationHandler.isLockedDriver }
}
