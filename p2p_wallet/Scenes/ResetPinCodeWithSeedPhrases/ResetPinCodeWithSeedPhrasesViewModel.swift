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
    let accountRepository: AccountRepository
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<ResetPinCodeWithSeedPhrasesNavigatableScene>()
    let error = BehaviorRelay<Error?>(value: nil)
    
    // MARK: - Input
    init(accountRepository: AccountRepository) {
        self.accountRepository = accountRepository
    }
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Actions
//    @objc func showDetail() {
//        
//    }
}

extension ResetPinCodeWithSeedPhrasesViewModel: PhrasesCreationHandler {
    func handlePhrases(_ phrases: [String]) {
        guard accountRepository.phrases == phrases else {
            error.accept(SolanaSDK.Error.other("Seed phrases is not correct"))
            return
        }
        navigationSubject.onNext(.createNewPasscode)
    }
}
