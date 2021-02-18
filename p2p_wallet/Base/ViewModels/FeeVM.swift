//
//  FeeVM.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/12/2020.
//

import Foundation
import RxSwift

class FeeVM: BaseVM<Double> {
    let solanaSDK: SolanaSDK
    let walletsVM: WalletsVM
    init(solanaSDK: SolanaSDK, walletsVM: WalletsVM) {
        self.solanaSDK = solanaSDK
        self.walletsVM = walletsVM
        super.init(initialData: 0)
    }
    
    override var request: Single<Double> {
        solanaSDK.getFees()
            .map {$0.feeCalculator?.lamportsPerSignature ?? 0}
            .map {
                let decimals = self.walletsVM.items.solWallet?.decimals ?? 9
                return Double($0) * pow(Double(10), -Double(decimals))
            }
    }
}
