//
//  MyBalancesVM.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/11/20.
//

import Foundation
import RxSwift

class BalancesVM: BaseVM<UInt64> {
    static var ofCurrentUser = BalancesVM()
    
    let accountPublicKey: String?
    var balance: UInt64 {data.value}
    
    init(accountPublicKey: String? = nil) {
        self.accountPublicKey = accountPublicKey ?? SolanaSDK.shared.accountStorage.account?.publicKey.base58EncodedString
        super.init(initialData: 0)
    }

    @discardableResult
    override func reload() -> Bool {
        guard super.reload(), let publicKey = accountPublicKey else {
            state.accept(.error(SolanaSDK.Error.accountNotFound))
            return false
        }
        state.accept(.loading)
        SolanaSDK.shared.getBalance(account: publicKey)
            .subscribe { (balance) in
                self.data.accept(balance)
                self.state.accept(.loaded)
            } onError: { (error) in
                self.state.accept(.error(error))
            }
            .disposed(by: disposeBag)
        return true
    }
}
