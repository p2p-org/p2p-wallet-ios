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
    func setupChannel(channel: DAppContainer.Channel)
}

extension DAppContainer {
    class ViewModel: NSObject {
        // MARK: - Dependencies
        
        // MARK: - Properties
        private var walletsRepository: WalletsRepository?
        private var dAppChannel: DAppContainer.Channel?
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
    }
}

extension DAppContainer.ViewModel: DAppContainerViewModelType {
    func setup(walletsRepository: WalletsRepository) {
        self.walletsRepository = walletsRepository
    }
    
    func setupChannel(channel: DAppContainer.Channel) {
        dAppChannel = channel
        channel.delegate = self
    }
    
    var navigationDriver: Driver<DAppContainer.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    // MARK: - Actions
    func navigate(to scene: DAppContainer.NavigatableScene) {
        navigationSubject.accept(scene)
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
