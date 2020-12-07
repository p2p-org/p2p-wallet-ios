//
//  FeeVM.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/12/2020.
//

import Foundation

class FeeVM: BaseVM<Double> {
    static let shared = FeeVM()
    
    private init() {
        super.init(initialData: 0)
        reload()
    }
    
    @discardableResult
    override func reload() -> Bool {
        guard super.reload() else {return false}
        SolanaSDK.shared.getFees()
            .map {$0.feeCalculator?.lamportsPerSignature ?? 0}
            .subscribe(onSuccess: {[weak self] fee in
                guard let strongSelf = self else {return}
                let decimals = WalletsVM.ofCurrentUser.items.first(where: {$0.symbol == "SOL"})?.decimals ?? 9
                strongSelf.data = Double(fee) * pow(Double(10), -Double(decimals))
                strongSelf.state.accept(.loaded(strongSelf.data))
            }, onError: {[weak self] error in
                self?.state.accept(.error(error))
            })
            .disposed(by: disposeBag)
        return true
    }
}
