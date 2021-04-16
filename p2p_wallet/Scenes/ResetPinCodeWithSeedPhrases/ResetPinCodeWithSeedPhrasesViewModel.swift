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
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<ResetPinCodeWithSeedPhrasesNavigatableScene>()
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    
    
    // MARK: - Actions
//    @objc func showDetail() {
//        
//    }
}

extension ResetPinCodeWithSeedPhrasesViewModel: PhrasesCreationHandler {
    func handlePhrases(_ phrases: [String]) {
        // TODO: - Verify and move to CreateNewPasscode
    }
}
