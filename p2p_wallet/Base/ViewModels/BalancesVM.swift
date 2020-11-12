//
//  MyBalancesVM.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/11/20.
//

import Foundation
import RxCocoa
import RxSwift

class BalancesVM {
    static var ofCurrentUser = BalancesVM()
    
    let accountPublicKey: String?
    init(accountPublicKey: String? = nil) {
        self.accountPublicKey = accountPublicKey ?? SolanaSDK.shared.accountStorage.account?.publicKey.base58EncodedString
    }
    
    let disposeBag = DisposeBag()
    let balance = BehaviorRelay<UInt64>(value: 0)
    let state = BehaviorRelay<FetcherState>(value: .loading)

    func reload() {
        guard let publicKey = accountPublicKey else {
            state.accept(.error(SolanaSDK.Error.accountNotFound))
            return
        }
        state.accept(.loading)
        SolanaSDK.shared.getBalance(account: publicKey)
            .subscribe { (balance) in
                self.balance.accept(balance)
                self.state.accept(.loaded)
            } onError: { (error) in
                self.state.accept(.error(error))
            }
            .disposed(by: disposeBag)
    }
}
