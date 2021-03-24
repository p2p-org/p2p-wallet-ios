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

class ChooseWalletViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    let myWalletsViewModel: BEListViewModelType
//    let otherWalletsViewModel: BEListViewModelType
    let firstSectionFilter: ((AnyHashable) -> Bool)?
    
    // MARK: - Subjects
    let selectedWallet = PublishSubject<Wallet>()
    
    // MARK: - Initializer
    init(
        myWalletsViewModel: BEListViewModelType,
//        otherWalletsViewModel: BEListViewModelType
        firstSectionFilter: ((AnyHashable) -> Bool)? = nil
    ) {
        self.myWalletsViewModel = myWalletsViewModel
//        self.otherWalletsViewModel = otherWalletsViewModel
        self.firstSectionFilter = firstSectionFilter
    }
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    
    
    // MARK: - Actions
//    @objc func showDetail() {
//        
//    }
}
