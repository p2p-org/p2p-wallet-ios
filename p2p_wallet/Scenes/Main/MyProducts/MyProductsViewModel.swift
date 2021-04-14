//
//  MyProductsViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/03/2021.
//

import UIKit
import RxSwift
import RxCocoa

enum MyProductsNavigatableScene {
    case addNewWallet
    case walletDetail(pubkey: String, symbol: String)
    case walletSettings(wallet: Wallet)
}

class MyProductsViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    let walletsViewModel: WalletsListViewModelType
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<MyProductsNavigatableScene>()
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Methods
    init(walletsViewModel: WalletsListViewModelType) {
        self.walletsViewModel = walletsViewModel
    }
    
    // MARK: - Actions
    @objc func addNewWallet() {
        navigationSubject.onNext(.addNewWallet)
    }
    
    func showWalletDetail(pubkey: String, symbol: String) {
        navigationSubject.onNext(.walletDetail(pubkey: pubkey, symbol: symbol))
    }
    
    func showWalletSettings(wallet: Wallet) {
        navigationSubject.onNext(.walletSettings(wallet: wallet))
    }
}
