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
    var firstSectionFilter: ((AnyHashable) -> Bool)?
    
    var keyword: String?
    
    // MARK: - Subjects
    let selectedWallet = PublishSubject<Wallet>()
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Initializer
    init(
        myWalletsViewModel: BEListViewModelType,
        tokensRepository: TokensRepository,
        showOtherWallets: Bool,
        firstSectionFilter: ((AnyHashable) -> Bool)? = nil
    ) {
        self.myWalletsViewModel = myWalletsViewModel
        if showOtherWallets {
            otherWalletsViewModel = OtherWalletsViewModel(tokensRepository: tokensRepository)
        } else {
            otherWalletsViewModel = nil
        }
        
        otherWalletsViewModel?.customFilter = { [weak self] wallet in
            guard let strongSelf = self else {return true}
            if strongSelf.myWalletsViewModel
                .getData(type: Wallet.self)
                .contains(where: { $0.token.symbol == wallet.token.symbol })
            {
                return false
            }
            if let keyword = strongSelf.keyword {
                return wallet.hasKeyword(keyword)
            }
            return true
        }
        
        let fFilter: ((AnyHashable) -> Bool)? = {[weak self] wallet in
            guard let strongSelf = self,
                let wallet = wallet as? Wallet
            else {return true}
            var isValid = firstSectionFilter?(wallet) ?? true
            if let keyword = strongSelf.keyword {
                isValid = isValid && wallet.hasKeyword(keyword)
            }
            return isValid
        }
        self.firstSectionFilter = fFilter
        
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
    
    func search(keyword: String) {
        // if search field was cleared
        if keyword.isEmpty {
            self.keyword = nil
        } else {
            self.keyword = keyword
        }
        
        // Update
        myWalletsViewModel.refreshUI()
        otherWalletsViewModel?.refreshUI()
    }
    
    // MARK: - Actions
//    @objc func showDetail() {
//        
//    }
}

private extension Wallet {
    func hasKeyword(_ keyword: String) -> Bool {
        token.symbol.lowercased().hasPrefix(keyword.lowercased()) ||
            token.symbol.lowercased().contains(keyword.lowercased()) ||
            token.name.lowercased().hasPrefix(keyword.lowercased()) ||
            token.name.lowercased().contains(keyword.lowercased())
    }
}
