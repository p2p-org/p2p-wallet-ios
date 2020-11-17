//
//  MyBalancesVM.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/11/20.
//

import Foundation
import RxSwift

class SolBalanceVM: BaseVM<Price> {
    static var ofCurrentUser = SolBalanceVM()
    
    let accountPublicKey: String?
    var balance: Price {data}
    
    init(accountPublicKey: String? = nil) {
        self.accountPublicKey = accountPublicKey ?? SolanaSDK.shared.accountStorage.account?.publicKey.base58EncodedString
        super.init(initialData: Price(from: "SOL", to: "USDT", value: 0, change24h: nil))
    }
    
    override func bind() {
        super.bind()
        PricesManager.bonfida.prices
            .filter {$0.contains(where: {$0.from == "SOL"})}
            .map {$0.first(where: {$0.from == "SOL"})!}
            .subscribe(onNext: {solPrice in
                switch self.state.value {
                case .loaded:
                    self.data = solPrice
                    self.state.accept(.loaded(solPrice))
                default:
                    break
                }
            })
            .disposed(by: disposeBag)
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
                var data = self.data
                data.value = Double(balance) * 0.000000001
                self.state.accept(.loaded(self.data))
            } onError: { (error) in
                self.state.accept(.error(error))
            }
            .disposed(by: disposeBag)
        return true
    }
}
