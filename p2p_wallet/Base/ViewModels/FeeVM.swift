//
//  FeeVM.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/12/2020.
//

import Foundation
import RxSwift

class FeeVM: BaseVM<Double> {
    static let shared = FeeVM()
    
    private init() {
        super.init(initialData: 0)
        reload()
    }
    
    override var request: Single<Double> {
        SolanaSDK.shared.getFees()
            .map {$0.feeCalculator?.lamportsPerSignature ?? 0}
            .map {
                let decimals = WalletsVM.ofCurrentUser.items.first(where: {$0.symbol == "SOL"})?.decimals ?? 9
                return Double($0) * pow(Double(10), -Double(decimals))
            }
    }
}
