//
//  ChooseWallet.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/07/2021.
//

import Foundation
import RxSwift
import RxCocoa
import BECollectionView

protocol WalletDidSelectHandler {
    func walletDidSelect(_ wallet: Wallet)
}

extension ChooseWallet {
    class ViewModel: ViewModelType {
        // MARK: - Nested type
        struct Input {
            
        }
        struct Output {
            let walletsViewModel: WalletsViewModel
        }
        
        // MARK: - Dependencies
        private let handler: WalletDidSelectHandler
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        
        let input: Input
        let output: Output
        
        // MARK: - Subject
        
        // MARK: - Initializer
        init(myWallets: [Wallet], handler: WalletDidSelectHandler) {
            self.handler = handler
            
            self.input = Input()
            self.output = Output(
                walletsViewModel: WalletsViewModel(myWallets: myWallets)
            )
            
            bind()
        }
        
        /// Bind subjects
        private func bind() {
            bindInputIntoSubjects()
            bindSubjectsIntoSubjects()
        }
        
        private func bindInputIntoSubjects() {
            
        }
        
        private func bindSubjectsIntoSubjects() {
            
        }
        
        // MARK: - Actions
        func selectWallet(_ wallet: Wallet) {
            handler.walletDidSelect(wallet)
        }
    }
    
    class WalletsViewModel: BEListViewModel<Wallet> {
        init(myWallets: [Wallet]) {
            
        }
        
        // MARK: - Actions
        func search(keyword: String) {
            
        }
    }
}
