//
//  MainViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/06/2021.
//

import Combine
import Foundation
import NameService
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

        @Injected private var accountStorage: AccountStorageType
        @Injected private var nameService: NameService
        @Injected private var nameStorage: NameStorageType

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

            Task {
                guard nameStorage.getName() == nil else { return }
                guard let account = accountStorage.account else { return }
                guard let name = try await nameService.getName(account.publicKey.base58EncodedString) else { return }
                nameStorage.save(name: name)
            }
        }
    }
}

extension Main.ViewModel: MainViewModelType {
    var authenticationStatusPublisher: AnyPublisher<AuthenticationPresentationStyle?, Never> {
        authenticationHandler
            .authenticationStatusPublisher
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
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
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    var isLockedPublisher: AnyPublisher<Bool, Never> {
        authenticationHandler.isLockedPublisher
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    func authenticate(presentationStyle: AuthenticationPresentationStyle?) {
        authenticationHandler.authenticate(presentationStyle: presentationStyle)
    }
}
