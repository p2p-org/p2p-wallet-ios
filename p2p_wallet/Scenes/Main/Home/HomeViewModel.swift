//
//  HomeViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/03/2021.
//

import UIKit
import RxSwift
import RxCocoa
import Action

enum HomeNavigatableScene {
    case buyToken
    case receiveToken
    case scanQr
    case sendToken(address: String? = nil)
    case swapToken
    case allProducts
    case profile
    case reserveName(owner: String)
    case walletDetail(wallet: Wallet)
    case walletSettings(wallet: Wallet)
}

class HomeViewModel {
    // MARK: - Constants
    
    // MARK: - Dependencies
    @Injected var keychainStorage: KeychainAccountStorage
    
    // MARK: - Properties
    let walletsRepository: WalletsRepository
    
    // MARK: - Subjects
    private let navigationSubject = PublishSubject<HomeNavigatableScene>()
    var navigationDriver: Driver<HomeNavigatableScene> {
        navigationSubject.asDriver(onErrorJustReturn: .profile)
    }
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Initializers
    init(walletsRepository: WalletsRepository) {
        self.walletsRepository = walletsRepository
    }
    
    // MARK: - Actions
    func navigationAction(scene: HomeNavigatableScene) -> CocoaAction {
        CocoaAction { [weak self] in
            self?.navigationSubject.onNext(scene)
            return .just(())
        }
    }
    
    func navigateToWalletSettingsAction() -> Action<Wallet, Void> {
        Action<Wallet, Void> { [weak self] wallet in
            self?.navigationSubject.onNext(.walletSettings(wallet: wallet))
            return .just(())
        }
    }
    
    func showHideHiddenWalletAction() -> CocoaAction {
        CocoaAction { [weak self] in
            self?.walletsRepository.toggleIsHiddenWalletShown()
            return .just(())
        }
    }
    
    func showWalletDetail(wallet: Wallet) {
        navigationSubject.onNext(.walletDetail(wallet: wallet))
    }
//    @objc func showDetail() {
//        
//    }
}

extension HomeViewModel: ReserveNameHandler {
    func handleName(_ name: String?) {
        if let name = name {
            keychainStorage.save(name: name)
            Defaults.forceCloseNameServiceBanner = true
        }
    }
}
