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

class CreateOrRestoreWalletViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let bag = DisposeBag()
    
    // MARK: - Subjects
    let navigationSubject = BehaviorRelay<CreateOrRestoreWalletNavigatableScene>(value: .welcome)
}
