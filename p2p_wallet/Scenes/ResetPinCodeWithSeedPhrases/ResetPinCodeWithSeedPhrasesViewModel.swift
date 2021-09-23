//
//  ResetPinCodeWithSeedPhrasesViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/04/2021.
//

import UIKit
import RxSwift
import RxCocoa

enum ResetPinCodeWithSeedPhrasesNavigatableScene {
    case enterSeedPhrases
    case createNewPasscode
}

class ResetPinCodeWithSeedPhrasesViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    @Injected private var accountStorage: KeychainAccountStorage
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<ResetPinCodeWithSeedPhrasesNavigatableScene>()
    let error = BehaviorRelay<Error?>(value: nil)
    
    // MARK: - Actions
    @objc func savePincode(_ code: String) {
        accountStorage.save(code)
    }
}

extension ResetPinCodeWithSeedPhrasesViewModel: PhrasesCreationHandler {
    func handlePhrases(_ phrases: [String]) {
        guard accountStorage.phrases == phrases else {
            error.accept(SolanaSDK.Error.other("Seed phrases is not correct"))
            return
        }
        navigationSubject.onNext(.createNewPasscode)
    }
}
