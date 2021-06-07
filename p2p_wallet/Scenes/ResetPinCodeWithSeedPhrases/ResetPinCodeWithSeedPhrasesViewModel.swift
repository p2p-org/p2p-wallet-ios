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
    let accountStorage: KeychainAccountStorage
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<ResetPinCodeWithSeedPhrasesNavigatableScene>()
    let error = BehaviorRelay<Error?>(value: nil)
    
    // MARK: - Input
    init(accountStorage: KeychainAccountStorage) {
        self.accountStorage = accountStorage
    }
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Actions
    @objc func savePincode(_ code: String) {
        accountStorage.save(code)
    }
}

extension ResetPinCodeWithSeedPhrasesViewModel: PhrasesCreationHandler {
    func handlePhrases(_ phrases: [String]) {
        accountStorage.getCurrentAccount()
            .map {$0?.phrase}
            .subscribe(onSuccess: {[weak self] myPhrases in
                guard phrases == myPhrases else {
                    self?.error.accept(SolanaSDK.Error.other("Seed phrases is not correct"))
                    return
                }
                self?.navigationSubject.onNext(.createNewPasscode)
            })
            .disposed(by: disposeBag)
    }
}
