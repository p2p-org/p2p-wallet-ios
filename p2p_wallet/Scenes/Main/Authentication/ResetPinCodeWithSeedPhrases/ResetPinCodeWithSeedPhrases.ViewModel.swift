//
//  ResetPinCodeWithSeedPhrasesViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/04/2021.
//

import UIKit
import RxSwift
import RxCocoa

protocol ResetPinCodeWithSeedPhrasesViewModelType {
    var navigatableSceneDriver: Driver<ResetPinCodeWithSeedPhrases.NavigatableScene> {get}
    var errorDriver: Driver<Error?> {get}
    
    func savePincode(_ code: String)
    func handlePhrases(_ phrases: [String])
}

extension ResetPinCodeWithSeedPhrases {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var accountStorage: KeychainAccountStorage
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        
        // MARK: - Subjects
        private let navigationSubject = BehaviorRelay<NavigatableScene>(value: .enterSeedPhrases)
        private let errorSubject = BehaviorRelay<Error?>(value: nil)
    }
}

extension ResetPinCodeWithSeedPhrases.ViewModel: ResetPinCodeWithSeedPhrasesViewModelType {
    var navigatableSceneDriver: Driver<ResetPinCodeWithSeedPhrases.NavigatableScene> {
        navigationSubject.asDriver()
    }
    
    var errorDriver: Driver<Error?> {
        errorSubject.asDriver()
    }
    
    // MARK: - Actions
    func savePincode(_ code: String) {
        accountStorage.save(code)
    }
    
    func handlePhrases(_ phrases: [String]) {
        guard accountStorage.phrases == phrases else {
            errorSubject.accept(SolanaSDK.Error.other("Seed phrases is not correct"))
            return
        }
        navigationSubject.accept(.createNewPasscode)
    }
}
