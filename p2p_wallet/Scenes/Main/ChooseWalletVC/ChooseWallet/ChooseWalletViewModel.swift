//
//  ChooseWalletViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/03/2021.
//

import UIKit
import RxSwift
import RxCocoa

class ChooseWalletViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let walletsVM: WalletsVM
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    init(walletsVM: WalletsVM) {
        self.walletsVM = walletsVM
    }
    
    // MARK: - Actions
//    @objc func showDetail() {
//        
//    }
}
