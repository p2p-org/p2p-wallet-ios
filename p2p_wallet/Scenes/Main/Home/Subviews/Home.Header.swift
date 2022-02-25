//
// Created by Giang Long Tran on 14.02.2022.
//

import Foundation

extension Home {
    class FloatingHeaderView: BECompositionView {
        private let viewModel: HomeViewModelType

        private(set) var preferredTopHeight: CGFloat = 90
        let bottomMaxHeight: CGFloat = 80
        let bottomMinHeight: CGFloat = 40

        var top: UIView!
        var collapseConstraint: NSLayoutConstraint!
        var bottomCollapseConstraint: NSLayoutConstraint!

        init(viewModel: HomeViewModelType) {
            self.viewModel = viewModel
            super.init()
        }

        override func build() -> UIView {
            BEContainer {
                BEZStack {
                    BalanceView(viewModel: viewModel)
                        .padding(.init(only: .bottom, inset: 35))
                        .withTag(2)

                    ColorfulHorizontalView {
//                        WalletActionButton(actionType: .buy) { [unowned self] in viewModel.navigate(to: .buyToken) }
                        WalletActionButton(actionType: .receive) { [unowned self] in viewModel.navigate(to: .receiveToken) }
                        WalletActionButton(actionType: .send) { [unowned self] in viewModel.navigate(to: .sendToken(address: nil)) }
                        WalletActionButton(actionType: .swap) { [unowned self] in viewModel.navigate(to: .swapToken) }
                    }
                    .withTag(1)
                }
            }.setup { view in
                guard let v1 = view.viewWithTag(1),
                    let v2 = view.viewWithTag(2)
                else { return }

                v2.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
                v1.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)

                top = v2
                collapseConstraint = v2.autoPinEdge(.bottom, to: .top, of: v1, withOffset: 0, relation: .equal)
                bottomCollapseConstraint = v1.autoSetDimension(.height, toSize: bottomMaxHeight)

                view.autoMatch(.height, to: .height, of: v1, withMultiplier: 1.0, relation: .greaterThanOrEqual)
            }
        }
    }
}
