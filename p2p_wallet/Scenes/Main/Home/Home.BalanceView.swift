//
//  Home.BalanceView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/11/2021.
//

import Foundation
import Charts
import BECollectionView
import RxSwift
import RxCocoa

extension Home {
    class BalanceView: BECompositionView {
        fileprivate var balanceLabel: UILabel!
        
        override func build() -> UIView {
            BEVStack(alignment: .center) {
                UILabel(text: L10n.balance)
                UIView(height: 4)
                UILabel(text: "", textSize: 28, weight: .bold).setupWithType(UILabel.self) { view in balanceLabel = view }
            }
        }
    }
}

extension Reactive where Base: Home.BalanceView {
    var balance: Binder<(data: [Wallet], state: BEFetcherState)> {
        Binder(base) { view, state in
            let label = view.balanceLabel!
            let fetcherState = state.1
            let data = state.0
            
            switch fetcherState {
            case .initializing:
                label.text = " "
            case .loading:
                label.text = L10n.loading + "..."
            case .loaded:
                let equityValue = data.reduce(0) { $0 + $1.amountInCurrentFiat }
                label.text = "\(Defaults.fiat.symbol) \(equityValue.toString(maximumFractionDigits: 2))"
            case .error:
                label.text = L10n.error.uppercaseFirst
            }
        }
    }
}