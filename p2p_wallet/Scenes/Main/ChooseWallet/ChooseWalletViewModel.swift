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
    let otherWalletsViewModel: OtherWalletsViewModel?
    let firstSectionFilter: ((AnyHashable) -> Bool)?
    
    // MARK: - Subjects
    let selectedWallet = PublishSubject<Wallet>()
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Initializer
    init(
        myWalletsViewModel: BEListViewModelType,
        showOtherWallets: Bool,
        firstSectionFilter: ((AnyHashable) -> Bool)? = nil
    ) {
        self.myWalletsViewModel = myWalletsViewModel
        if showOtherWallets {
            otherWalletsViewModel = OtherWalletsViewModel()
        } else {
            otherWalletsViewModel = nil
        }
        self.firstSectionFilter = firstSectionFilter
        
        otherWalletsViewModel?.customFilter = { [weak self] wallet in
            guard let strongSelf = self else {return true}
            if strongSelf.myWalletsViewModel
                .getData(type: Wallet.self)
                .contains(where: { $0.symbol == wallet.symbol })
            {
                return false
            }
            return true
        }
        bind()
    }
    
    func bind() {
        myWalletsViewModel.dataDidChange
            .map {self.myWalletsViewModel.currentState}
            .subscribe(onNext: {[weak self] state in
                switch state {
                case .initializing, .loading, .error:
                    self?.otherWalletsViewModel?.setState(state, withData: [])
                case .loaded:
                    self?.otherWalletsViewModel?.reload()
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Actions
//    @objc func showDetail() {
//        
//    }
}
