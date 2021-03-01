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
    // MARK: - Properties
    let walletsVM: WalletsVM
    let pubkey: String
    
    // MARK: - Subject
//    private let wallet = BehaviorRelay<Wallet?>(value: nil)
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    init(walletsVM: WalletsVM, pubkey: String) {
        self.walletsVM = walletsVM
        self.pubkey = pubkey
        super.init()
    }
    
    override func bind() {
        super.bind()
        walletsVM.state
            .map { state -> Wallet? in
                switch state {
                case .loaded(let data):
                    return data.first(where: {$0.pubkey == self.pubkey})
                default:
                    return nil
                }
            }
            .map {wallet -> [TokenSettings] in
                [
                    .visibility(!(wallet?.isHidden ?? false)),
                    .close
                ]
            }
            .subscribe(onNext: { (settings) in
                self.items = settings
                self.state.accept(.loaded(settings))
            })
            .disposed(by: disposeBag)
    }
    
    override func reload() {}
    
    // MARK: - Actions
    @objc func toggleHideWallet() {
        guard let wallet = walletsVM.items.first(where: {$0.pubkey == pubkey}) else {return}
        if wallet.isHidden {
            walletsVM.unhideWallet(wallet)
        } else {
            walletsVM.hideWallet(wallet)
        }
    }
    
    @objc func showWallet() {
        
    }
}
