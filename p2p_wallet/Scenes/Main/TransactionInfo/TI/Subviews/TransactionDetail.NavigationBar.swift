//
//  TransactionDetail.NavigationBar.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/03/2022.
//

import Foundation
import RxCocoa
import SolanaSwift

extension TransactionDetail {
    final class NavigationBar: NewWLNavigationBar {
        func driven(with driver: Driver<SolanaSDK.ParsedTransaction?>) -> TransactionDetail.NavigationBar {
            
            
            
            return self
        }
    }
}
