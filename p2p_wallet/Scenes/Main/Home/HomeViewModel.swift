//
//  HomeViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/03/2021.
//

import UIKit
import RxSwift
import RxCocoa
import Action

enum HomeNavigatableScene {
    case receiveToken
    case scanQr
    case sendToken(address: String? = nil)
    case swapToken
    case allProducts
    case profile
    case walletDetail(wallet: Wallet)
    case walletSettings(wallet: Wallet)
}

class HomeViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let walletsVM: WalletsVM
    let homeCollectionViewModel: HomeCollectionViewModel
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<HomeNavigatableScene>()
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Initializers
    init(walletsVM: WalletsVM) {
        self.walletsVM = walletsVM
        self.homeCollectionViewModel = HomeCollectionViewModel(walletsVM: walletsVM)
    }
    
    // MARK: - Actions
    func navigationAction(scene: HomeNavigatableScene) -> CocoaAction {
        CocoaAction {
            self.navigationSubject.onNext(scene)
            return .just(())
        }
    }
//    @objc func showDetail() {
//        
//    }
}
