//
//  MainViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/06/2021.
//

import Foundation
import RxCocoa
import RxSwift

protocol MainViewModelType {
    var authenticationStatusDriver: Driver<AuthenticationPresentationStyle?> { get
    } // nil if non authentication process is processing
    var isLockedDriver: Driver<Bool> { get }

    func authenticate(presentationStyle: AuthenticationPresentationStyle?)
}

class MainViewModel {
    // MARK: - Dependencies

    @Injected private var socket: SolanaSDK.Socket
    @Injected private var pricesService: PricesServiceType
    @Injected private var lockAndMint: RenVMLockAndMintServiceType // start service right here by triggering resolver
    @Injected private var burnAndRelease: RenVMBurnAndReleaseServiceType // start service right here by triggering resolver
    @Injected private var authenticationHandler: AuthenticationHandlerType

    private let transactionAnalytics = [
        Resolver.resolve(SwapTransactionAnalytics.self),
    ]

    // MARK: - Initializer

    init() {
        socket.connect()
        pricesService.startObserving()
    }

    deinit {
        socket.disconnect()
        pricesService.stopObserving()
        debugPrint("\(String(describing: self)) deinited")
    }
}

extension MainViewModel: MainViewModelType {
    var authenticationStatusDriver: Driver<AuthenticationPresentationStyle?> {
        authenticationHandler.authenticationStatusDriver
    }

    var isLockedDriver: Driver<Bool> {
        authenticationHandler.isLockedDriver
    }

    func authenticate(presentationStyle: AuthenticationPresentationStyle?) {
        authenticationHandler.authenticate(presentationStyle: presentationStyle)
    }
}
