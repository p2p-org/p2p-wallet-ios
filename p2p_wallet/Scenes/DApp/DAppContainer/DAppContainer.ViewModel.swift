//
//  DAppContainer.ViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 25.11.21.
//

import Foundation
import RxSwift
import RxCocoa
import WebKit

protocol DAppContainerViewModelType {
    var navigationDriver: Driver<DAppContainer.NavigatableScene?> { get }
    func navigate(to scene: DAppContainer.NavigatableScene)
    
    func setup(walletsRepository: WalletsRepository)
    func getWebviewConfiguration() -> WKWebViewConfiguration
}

extension DAppContainer {
    class ViewModel: NSObject {
        // MARK: - Dependencies
        
        // MARK: - Properties
        private var walletsRepository: WalletsRepository?
        private var dAppChannel: Channel = Channel()
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        
        override init() {
            super.init()
            dAppChannel.setDelegate(self)
        }
    }
}

extension DAppContainer.ViewModel: DAppContainerViewModelType {
    var navigationDriver: Driver<DAppContainer.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    // MARK: - Actions
    func navigate(to scene: DAppContainer.NavigatableScene) {
        navigationSubject.accept(scene)
    }
    
    func setup(walletsRepository: WalletsRepository) {
        self.walletsRepository = walletsRepository
    }
    
    func getWebviewConfiguration() -> WKWebViewConfiguration {
        dAppChannel.getWebviewConfiguration()
    }
}

extension DAppContainer.ViewModel: DAppChannelDelegate {
    func connect() -> Single<String> {
        guard let repository = walletsRepository else {
            return .error(NSError(domain: "DAppChannel", code: 400, userInfo: [NSLocalizedDescriptionKey: "Platform is not ready"]))
        }
        
        guard let pubKey = repository.getWallets().first(where: { $0.isNativeSOL })?.pubkey else {
            return .error(NSError(domain: "DAppChannel", code: 400, userInfo: [NSLocalizedDescriptionKey: "Can not find wallet address"]))
        }
        
        return .just(pubKey)
    }
    
    func signTransaction() -> Single<String> {
        fatalError("signTransaction() has not been implemented")
    }
    
    func signTransactions() -> Single<[String]> {
        fatalError("signTransactions() has not been implemented")
    }
}
