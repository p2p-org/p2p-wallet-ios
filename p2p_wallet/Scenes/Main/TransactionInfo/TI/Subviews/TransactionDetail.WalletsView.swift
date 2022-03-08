//
//  TransactionDetail.WalletsView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/03/2022.
//

import Foundation
import UIKit
import RxCocoa
import SolanaSwift

extension TransactionDetail {
    final class WalletsView: UIStackView {
        init() {
            super.init(frame: .zero)
            set(axis: .horizontal, spacing: 8, alignment: .center, distribution: .fill)
        }
        
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func driven(with driver: Driver<SolanaSDK.ParsedTransaction?>) -> TransactionDetail.WalletsView {
            
            return self
        }
    }
}
