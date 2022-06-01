//
//  MainViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/06/2021.
//

import Foundation
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

        @Injected private var socket: SolanaSDK.Socket
        @Injected private var pricesService: PricesServiceType
        @Injected private var lockAndMint: RenVMLockAndMintServiceType // start service right here by triggering resolver
        @Injected private var burnAndRelease: BurnAndReleaseService
        @Injected private var authenticationHandler: AuthenticationHandlerType
        @Injected private var notificationService: NotificationService

        private let transactionAnalytics = [
            Resolver.resolve(SwapTransactionAnalytics.self),
        ]

        let viewDidLoad = PublishRelay<Void>()

        // MARK: - Initializer

        init() {
            socket.connect()
            pricesService.startObserving()
            burnAndRelease.resume()
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
