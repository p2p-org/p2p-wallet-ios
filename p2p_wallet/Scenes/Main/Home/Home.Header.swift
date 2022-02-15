//
// Created by Giang Long Tran on 14.02.2022.
//

import Foundation

extension Home {
    class FloatingHeaderView: BECompositionView {
        var balanceView: BalanceView!
        
        var top: UIView!
        var collapseConstraint: NSLayoutConstraint!
        var bottomCollapseConstraint: NSLayoutConstraint!
        
        private(set) var preferredTopHeight: CGFloat = 90
        let bottomMaxHeight: CGFloat = 80
        let bottomMinHeight: CGFloat = 40
        
        override func build() -> UIView {
            BEContainer {
                BEZStack {
                    BalanceView()
                        .setupWithType(BalanceView.self) { view in balanceView = view }
                        .padding(.init(x: 0, y: 18))
                        .withTag(2)
        
                    ColorfulHorizontalView {
                        WalletActionButton(actionType: .buy) {}
                        WalletActionButton(actionType: .receive) {}
                        WalletActionButton(actionType: .send) {}
                        WalletActionButton(actionType: .swap) {}
                    }
                        .withTag(1)
                        .padding(.init(only: .top, inset: 18))
                        .withTag(3)
                }
            }.setup { view in
                guard let v1 = view.viewWithTag(1),
                      let v2 = view.viewWithTag(2),
                      let v3 = view.viewWithTag(3)
                    else { return }
    
                v2.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
                v3.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
    
                top = v2
                collapseConstraint = v2.autoPinEdge(.bottom, to: .top, of: v3, withOffset: 0, relation: .equal)
                bottomCollapseConstraint = v1.autoSetDimension(.height, toSize: bottomMaxHeight)
    
                view.autoMatch(.height, to: .height, of: v3, withMultiplier: 1.0, relation: .greaterThanOrEqual)
            }
        }
    }
}