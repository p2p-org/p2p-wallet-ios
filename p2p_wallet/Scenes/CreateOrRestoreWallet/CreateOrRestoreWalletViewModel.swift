//
//  CreateOrRestoreWalletViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import UIKit
import RxSwift
import RxCocoa

enum CreateOrRestoreWalletNavigatableScene {
    case welcome
    case createWallet
    case restoreWallet
}

protocol CreateOrRestoreWalletHandler {
    func creatingWalletDidComplete()
    func restoringWalletDidComplete()
    func creatingOrRestoringWalletDidCancel()
}

class CreateOrRestoreWalletViewModel: ViewModelType {
    // MARK: - NestedType
    struct Input {
        
    }
    struct Output {
        let navigation: Driver<CreateOrRestoreWalletNavigatableScene>
    }
    
    // MARK: - Dependencies
    let analyticsManager: AnalyticsManagerType
    
    // MARK: - Properties
    private let bag = DisposeBag()
    let input: Input
    let output: Output
    
    // MARK: - Initializer
    init(analyticsManager: AnalyticsManagerType) {
        self.analyticsManager = analyticsManager
        self.input = Input()
        self.output = Output(
            navigation: navigationSubject.asDriver()
        )
    }
    
    // MARK: - Subjects
    private let navigationSubject = BehaviorRelay<CreateOrRestoreWalletNavigatableScene>(value: .welcome)
    
    // MARK: - Actions
    @objc func navigateToCreateWallet() {
        analyticsManager.log(event: .landingCreateWalletClick)
        navigationSubject.accept(.createWallet)
    }
    
    @objc func navigateToRestoreWallet() {
        analyticsManager.log(event: .landingIHaveWalletClick)
        navigationSubject.accept(.restoreWallet)
    }
}
