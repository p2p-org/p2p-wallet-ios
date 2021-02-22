//
//  CreateSecurityKeysViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/02/2021.
//

import UIKit
import RxSwift
import RxCocoa

class CreateSecurityKeysViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    
    // MARK: - Subjects
    let phrasesSubject = BehaviorRelay<[String]>(value: [])
    
    // MARK: - Input
    let checkBoxIsSelectedInput = BehaviorRelay<Bool>(value: false)
    
    init() {
        createPhrases()
    }
    
    // MARK: - Actions
    @objc func createPhrases() {
        let mnemonic = Mnemonic()
        self.phrasesSubject.accept(mnemonic.phrase)
    }
    
    @objc func copyToClipboard() {
        UIApplication.shared.copyToClipboard(phrasesSubject.value.joined(separator: " "))
    }
}
