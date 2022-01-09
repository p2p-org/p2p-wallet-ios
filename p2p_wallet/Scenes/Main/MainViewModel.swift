//
//  MainViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/06/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol MainViewModelType {
    var authenticationStatusDriver: Driver<AuthenticationPresentationStyle?> { get } // nil if non authentication process is processing
    func authenticate(presentationStyle: AuthenticationPresentationStyle?)
}

class MainViewModel {
    // MARK: - Dependencies
    @Injected private var socket: SolanaSDK.Socket
    @Injected private var pricesService: PricesServiceType
    @Injected private var lockAndMint: RenVMLockAndMintServiceType // start service right here by triggering resolver
    @Injected private var burnAndRelease: RenVMBurnAndReleaseServiceType // start service right here by triggering resolver
    @Injected private var authenticationHandler: AuthenticationHandlerType
    
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
    
    func authenticate(presentationStyle: AuthenticationPresentationStyle?) {
        authenticationHandler.authenticate(presentationStyle: presentationStyle)
    }
}
