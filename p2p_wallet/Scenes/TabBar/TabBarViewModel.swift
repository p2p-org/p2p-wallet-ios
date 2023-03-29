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
import SolanaSwift
import Combine

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
    let viewDidLoad = PassthroughSubject<Void, Never>()

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
    var authenticationStatusPublisher: AnyPublisher<AuthenticationPresentationStyle?, Never> {
        authenticationHandler.authenticationStatusPublisher
    }

    var moveToHistory: AnyPublisher<Void, Never> {
        Publishers.Merge(
            notificationService.showNotification
                .filter { $0 == .history }
                .map { _ in () },
            viewDidLoad
                .filter { [weak self] in
                    self?.notificationService.showFromLaunch == true
                }
                .handleEvents(receiveOutput: { [weak self] _ in
                    self?.notificationService.notificationWasOpened()
                })
        )
        .map { _ in () }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    var moveToIntercomSurvey: AnyPublisher<String, Never> {
        Publishers.Merge(
            authenticationHandler
                .isLockedPublisher
                .filter { value in
                    GlobalAppState.shared.surveyID != nil && value == false
                }
                .map {_ in ()},

            viewDidLoad
                .filter { [weak self] in
                    self?.notificationService.showFromLaunch == true
                }
        )
        .map { _ in () }
        .map {
            GlobalAppState.shared.surveyID ?? ""
        }
        .handleEvents(receiveOutput: { _ in
            GlobalAppState.shared.surveyID = nil
        })
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    var moveToSendViaLinkClaim: AnyPublisher<String, Never> {
        Publishers.Merge(
            authenticationHandler
                .isLockedPublisher
                .filter { value in
                    GlobalAppState.shared.sendViaLinkSeed != nil && value == false
                }
                .map {_ in ()},
            
            viewDidLoad
                .filter { [weak self] in
                    self?.notificationService.showFromLaunch == true
                }
        )
        .map { _ in () }
        .map {
            GlobalAppState.shared.sendViaLinkSeed ?? ""
        }
        .handleEvents(receiveOutput: { _ in
            GlobalAppState.shared.sendViaLinkSeed = nil
        })
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    var isLockedPublisher: AnyPublisher<Bool, Never> { authenticationHandler.isLockedPublisher }
}
