//
//  MainViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/06/2021.
//

import Combine
import Foundation
import RenVMSwift
import Resolver
import SolanaSwift

protocol MainViewModelType {
    var authenticationStatusPublisher: AnyPublisher<AuthenticationPresentationStyle?, Never> { get
    } // nil if non authentication process is processing
    var viewDidLoad: PassthroughSubject<Void, Never> { get }
    var moveToHistory: AnyPublisher<Void, Never> { get }
    var isLockedPublisher: AnyPublisher<Bool, Never> { get }

    func authenticate(presentationStyle: AuthenticationPresentationStyle?)
}

extension Main {
    final class ViewModel: BaseViewModel {
        // MARK: - Dependencies

        @Injected private var socket: Socket
        @Injected private var pricesService: PricesServiceType
        @Injected private var lockAndMint: LockAndMintService
        @Injected private var burnAndRelease: BurnAndReleaseService
        @Injected private var authenticationHandler: AuthenticationHandlerType
        @Injected private var notificationService: NotificationService

        private let transactionAnalytics = [
            Resolver.resolve(SwapTransactionAnalytics.self),
        ]

        let viewDidLoad = PassthroughSubject<Void, Never>()

        // MARK: - Initializer

        override init() {
            super.init()
            socket.connect()
            burnAndRelease.resume()
            Task {
                await pricesService.startObserving()
                try await lockAndMint.resume()
            }
        }
    }
}

extension Main.ViewModel: MainViewModelType {
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
                .handleEvents(receiveOutput: { [weak self] in
                    self?.notificationService.notificationWasOpened()
                })
        )
            .map { _ in () }
            .replaceError(with: ())
            .eraseToAnyPublisher()
    }

    var isLockedPublisher: AnyPublisher<Bool, Never> {
        authenticationHandler.isLockedPublisher
    }

    func authenticate(presentationStyle: AuthenticationPresentationStyle?) {
        authenticationHandler.authenticate(presentationStyle: presentationStyle)
    }
}
