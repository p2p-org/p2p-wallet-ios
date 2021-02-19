//
//  CreateWalletViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import UIKit
import RxSwift
import RxCocoa

enum CreateWalletNavigatableScene {
    case createPhrases
    case completed
    case dismiss
}

class CreateWalletViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let bag = DisposeBag()
    let completion: () -> Void
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<CreateWalletNavigatableScene>()
    
    init(completion: @escaping () -> Void) {
        self.completion = completion
    }
    
    func finish() {
        navigationSubject.onNext(.dismiss)
        completion()
    }
}
