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
    case dismiss
}

class CreateWalletViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let bag = DisposeBag()
    let handler: CreateOrRestoreWalletHandler
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<CreateWalletNavigatableScene>()
    
    init(handler: CreateOrRestoreWalletHandler) {
        self.handler = handler
    }
    
    func finish() {
        navigationSubject.onNext(.dismiss)
        handler.creatingOrRestoringWalletDidComplete()
    }
}
