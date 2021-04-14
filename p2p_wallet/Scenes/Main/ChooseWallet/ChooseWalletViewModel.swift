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
    
    var originalMyWallets: [Wallet]?
    var originalOtherWallets: [Wallet]?
    
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
    
    func searchDidBegin() {
        originalMyWallets = myWalletsViewModel.getData(type: Wallet.self)
        originalOtherWallets = otherWalletsViewModel?.getData(type: Wallet.self)
    }
    
    func search(keyword: String) {
        // if search field was cleared
        if keyword.isEmpty {
            myWalletsViewModel.setState(.loaded, withData: originalMyWallets ?? [])
            otherWalletsViewModel?.setState(.loaded, withData: originalOtherWallets ?? [])
            return
        }
        
        // mark
        let filter: (Wallet) -> Bool = {wallet in
            wallet.symbol.lowercased().hasPrefix(keyword.lowercased())
        }
        
        // apply search
        if let wallets = originalMyWallets {
            myWalletsViewModel.setState(.loaded, withData: wallets.filter(filter))
        }
        
        if let wallets = originalOtherWallets {
            otherWalletsViewModel?.setState(.loaded, withData: wallets.filter(filter))
        }
    }
    
    func searchDidEnd() {
        if let wallets = originalMyWallets {
            myWalletsViewModel.setState(.loaded, withData: wallets)
        }
        if let wallets = originalOtherWallets {
            otherWalletsViewModel?.setState(.loaded, withData: wallets)
        }
        originalMyWallets = nil
        originalOtherWallets = nil
    }
    
    // MARK: - Actions
//    @objc func showDetail() {
//        
//    }
}
