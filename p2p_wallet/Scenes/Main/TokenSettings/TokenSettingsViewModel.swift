//
//  TokenSettingsViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/02/2021.
//

import UIKit
import RxSwift
import RxCocoa

class TokenSettingsViewModel: ListViewModel<TokenSettings> {
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    
    override var request: Single<[TokenSettings]> {
        .just([
            .visibility(true),
            .close
        ])
    }
    // MARK: - Actions
//    @objc func showDetail() {
//        
//    }
}
