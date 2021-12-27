//
//  CreateOrRestoreWallet.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import UIKit
import RxSwift
import RxCocoa

protocol CreateOrRestoreWalletViewModelType {
    var navigatableSceneDriver: Driver<CreateOrRestoreWallet.NavigatableScene?> {get}
    
    func navigateToCreateWalletScene()
    func navigateToRestoreWalletScene()
}

extension CreateOrRestoreWallet {
    class ViewModel {
        // MARK: - Dependencies
        @Injected var analyticsManager: AnalyticsManagerType
        
        // MARK: - Properties
        private let bag = DisposeBag()
        
        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }
        
        // MARK: - Subjects
        private let navigatableSceneSubject = BehaviorRelay<CreateOrRestoreWallet.NavigatableScene?>(value: nil)
    }
}

extension CreateOrRestoreWallet.ViewModel: CreateOrRestoreWalletViewModelType {
    var navigatableSceneDriver: Driver<CreateOrRestoreWallet.NavigatableScene?> {
        navigatableSceneSubject.asDriver()
    }
    
    // MARK: - Actions
    func navigateToCreateWalletScene() {
        analyticsManager.log(event: .firstInCreateWalletClick)
        navigatableSceneSubject.accept(.createWallet)
    }
    
    func navigateToRestoreWalletScene() {
        analyticsManager.log(event: .firstInIHaveWalletClick)
        analyticsManager.log(event: .recoveryOpen(fromPage: "first_in"))
        navigatableSceneSubject.accept(.restoreWallet)
    }
}
