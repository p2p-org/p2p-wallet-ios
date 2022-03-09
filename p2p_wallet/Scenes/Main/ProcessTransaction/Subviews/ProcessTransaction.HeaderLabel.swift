//
//  HeaderLabel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 06/03/2022.
//

import Foundation
import RxSwift
import RxCocoa

extension ProcessTransaction {
    final class HeaderLabel: UILabel {
        private let disposeBag = DisposeBag()
        
        func driven(with transactionInfoDriver: Driver<PendingTransaction>) -> Self {
            transactionInfoDriver
                
            return self
        }
    }
}
