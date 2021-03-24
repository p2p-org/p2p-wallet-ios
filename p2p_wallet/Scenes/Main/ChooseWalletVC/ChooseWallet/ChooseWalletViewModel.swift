//
//  ChooseWalletViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/03/2021.
//

import UIKit
import RxSwift
import RxCocoa
import BECollectionView

enum ChooseWalletNavigatableScene {
//    case detail
}

class ChooseWalletViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    let myWalletsViewModel: BEListViewModelType
//    let otherWalletsViewModel: BEListViewModelType
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<ChooseWalletNavigatableScene>()
    
    // MARK: - Initializer
    init(
        myWalletsViewModel: BEListViewModelType
//        otherWalletsViewModel: BEListViewModelType
    ) {
        self.myWalletsViewModel = myWalletsViewModel
//        self.otherWalletsViewModel = otherWalletsViewModel
    }
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    
    
    // MARK: - Actions
//    @objc func showDetail() {
//        
//    }
}
