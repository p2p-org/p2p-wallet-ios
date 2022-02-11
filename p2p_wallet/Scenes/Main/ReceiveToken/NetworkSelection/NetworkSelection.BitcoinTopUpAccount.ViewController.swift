//
// Created by Giang Long Tran on 08.02.2022.
//

import BEPureLayout
import RxCocoa
import RxSwift
import UIKit
import Resolver

extension ReceiveToken {
    class BitcoinTopUpAccountScene: WLBottomSheet {
        let viewModel: ReceiveSceneModel
        let onCompletion: BEVoidCallback?
    
        init(viewModel: ReceiveSceneModel, onCompletion: BEVoidCallback?) {
            self.viewModel = viewModel
            self.onCompletion = onCompletion
            super.init()
        }

        override var preferredNavigationBarStype: NavigationBarStyle { .hidden }

        override var padding: UIEdgeInsets { .zero }

        override func build() -> UIView? {
            UIStackView(axis: .vertical, alignment: .fill) {

                // Title
                UIStackView(axis: .vertical, alignment: .center) {
                    UILabel(text: L10n.receivingViaBitcoinNetwork, textSize: 20, weight: .semibold)
                        .padding(.init(only: .bottom, inset: 4))
                    UILabel(text: L10n.makeSureYouUnderstandTheAspects, textColor: .textSecondary)
                }.padding(.init(all: 18, excludingEdge: .bottom))

                // Icon
                BEZStack {
                    UIView.defaultSeparator().withTag(1)
                    UIImageView(width: 44, height: 44, image: .squircleAlert)
                        .centered(.horizontal)
                        .withTag(2)
                }.setup { view in
                    if let subview = view.viewWithTag(1) {
                        subview.autoPinEdge(toSuperviewEdge: .left)
                        subview.autoPinEdge(toSuperviewEdge: .right)
                        subview.autoCenterInSuperView(leftInset: 0, rightInset: 0)
                    }
                    if let subview = view.viewWithTag(2) {
                        subview.autoPinEdgesToSuperviewEdges()
                    }
                }.padding(.init(x: 0, y: 18))

                // Content
                UIStackView(axis: .vertical, spacing: 12, alignment: .fill) {
                    ReceiveToken.textBuilder(text: L10n.aRenBTCAccountIsRequiredToReceiveBitcoinsOverTheBitcoinNetwork.asMarkdown())
                    ReceiveToken.textBuilder(text: L10n.yourWalletListDoesNotContainARenBTCAccountAndToCreateOneYouNeedToMakeATransaction.asMarkdown())
                    ReceiveToken.textBuilder(text: L10n.youDonTHaveFundsToPayForAccountCreationButIfSomeoneSendsRenBTCToYourAddressItWillBeCreatedForYou.asMarkdown())
                    
                    // Buy button
                    WLStepButton.main(image: .walletAdd.withTintColor(.white), text: L10n.topUpYourAccount)
                        .onTap { [unowned self] in
                            viewModel.showBuyScreen()
                            self.back()
                        }
                        .padding(.init(only: .top, inset: 36))
    
                    WLStepButton.sub(text: L10n.shareYourSolanaNetworkAddress)
                        .onTap { [unowned self] in
                            viewModel.receiveSolanaViewModel.saveAction()
                            self.back()
                        }
                        .padding(.init(x: 28, y: 0))
                }.padding(.init(x: 18, y: 0))
            }
        }
    }
}
