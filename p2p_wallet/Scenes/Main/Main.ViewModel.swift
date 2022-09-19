//
//  MainViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/06/2021.
//

import Foundation
import NameService
import RenVMSwift
import Resolver
import RxCocoa
import RxSwift
import SolanaSwift

protocol MainViewModelType {
    var authenticationStatusDriver: Driver<AuthenticationPresentationStyle?> { get
    } // nil if non authentication process is processing
    var viewDidLoad: PublishRelay<Void> { get }
    var moveToHistory: Driver<Void> { get }
    var isLockedDriver: Driver<Bool> { get }

    func authenticate(presentationStyle: AuthenticationPresentationStyle?)
}

extension Main {
    final class ViewModel {
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
        @Injected private var userWalletManager: UserWalletManager
        @Injected private var pincodeService: PincodeService

        private let transactionAnalytics = [
            Resolver.resolve(SwapTransactionAnalytics.self),
        ]

        let viewDidLoad = PublishRelay<Void>()

        // MARK: - Initializer

        init() {
            socket.connect()
            pricesService.startObserving()
            burnAndRelease.resume()
            Task {
                try await lockAndMint.resume()
            }

            Task {
                guard nameStorage.getName() == nil else { return }
                guard let account = accountStorage.account else { return }
                guard let name = try await nameService.getName(account.publicKey.base58EncodedString) else { return }
                nameStorage.save(name: name)
            }
        }

        deinit {
            socket.disconnect()
            pricesService.stopObserving()
            debugPrint("\(String(describing: self)) deinited")
        }
    }
}

extension Main.ViewModel: MainViewModelType {
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

    var isLockedDriver: Driver<Bool> {
        authenticationHandler.isLockedDriver
    }

    func authenticate(presentationStyle: AuthenticationPresentationStyle?) {
        authenticationHandler.authenticate(presentationStyle: presentationStyle)
    }
}
