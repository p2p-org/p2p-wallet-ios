//
// Created by Giang Long Tran on 15.02.2022.
//

import UIKit

extension Home {
    class EmptyView: BECompositionView {
        private let viewModel: HomeViewModelType
        let refreshControl = UIRefreshControl()
    
        init(viewModel: HomeViewModelType) {
            self.viewModel = viewModel
            super.init()
            
            refreshControl.addTarget(self, action: #selector(reload), for: .valueChanged)
        }
    
        override func build() -> UIView {
            BEScrollView(alwaysBounceVertical: true, refreshControl: refreshControl) {
                BEVStack {
                    // Logo
                    UIImageView(width: 263, height: 263, image: .rocketFront, contentMode: .scaleAspectFit)
                    UILabel(text: L10n.topUpYourAccountToGetStarted, textSize: 28, weight: .bold, numberOfLines: 3, textAlignment: .center)
                    UIView(height: 10)
                    UILabel(text: L10n.makeYourFirstDepositOrBuyWithYourCreditCardOrApplePay, textColor: .secondaryLabel, numberOfLines: 3, textAlignment: .center)
                    UIView(height: 25)
                    
                    // Buttons
                    ColorfulHorizontalView {
                        WalletActionButton(actionType: .buy) { [unowned self] in viewModel.navigate(to: .buyToken) }
                        WalletActionButton(actionType: .receive) { [unowned self] in viewModel.navigate(to: .receiveToken) }
                        WalletActionButton(actionType: .send) { [unowned self] in viewModel.navigate(to: .sendToken(address: nil)) }
                        WalletActionButton(actionType: .swap) { [unowned self] in viewModel.navigate(to: .swapToken) }
                    }.frame(height: 80)
        
                    UIView.spacer
                }.padding(.init(x: 18, y: 0))
            }
        }
        
        @objc func reload() {
            viewModel.walletsRepository.reload()
        }
    }
}