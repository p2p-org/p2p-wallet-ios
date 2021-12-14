//
//  SendTokenTokenAndAmountHandler.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/12/2021.
//

import Foundation
import RxCocoa

protocol SendTokenTokenAndAmountHandler {
    var walletSubject: BehaviorRelay<Wallet?> {get}
    var amountSubject: BehaviorRelay<Double?> {get}
}

extension SendTokenTokenAndAmountHandler {
    var walletDriver: Driver<Wallet?> {
        walletSubject.asDriver()
    }
    
    var amountDriver: Driver<Double?> {
        amountSubject.asDriver()
    }
    
    func chooseWallet(_ wallet: Wallet) {
        walletSubject.accept(wallet)
    }
    
    func enterAmount(_ amount: Double?) {
        amountSubject.accept(amount)
    }
    
    func getSelectedAmount() -> Double? {
        amountSubject.value
    }
    
    func getSelectedWallet() -> Wallet? {
        walletSubject.value
    }
}
