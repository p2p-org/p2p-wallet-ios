//
// Created by Giang Long Tran on 08.02.2022.
//

import BEPureLayout
import RxCocoa
import RxSwift
import UIKit

extension ReceiveToken {
    class BitcoinCreateAccountScene: WLBottomSheet {
        @Injected var walletRepository: WalletsRepository
        private let viewModel: ReceiveTokenBitcoinViewModelType
        private let onCompletion: BEVoidCallback?
    
        // Internal state
        var payingTokenRelay: BehaviorRelay<PayingFeeToken?> = BehaviorRelay(value: nil)
    
        init(viewModel: ReceiveTokenBitcoinViewModelType, onCompletion: BEVoidCallback?) {
            self.viewModel = viewModel
            self.onCompletion = onCompletion
            super.init()
    
            if let wallet = walletRepository.getWallets().first { $0.amount > 0 } {
                payingTokenRelay.accept(try? PayingFeeToken.fromWallet(wallet: wallet))
            }
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

                UIStackView(axis: .vertical, spacing: 12, alignment: .fill) {
                    ReceiveToken.textBuilder(text: L10n.yourWalletListDoesNotContainARenBTCAccountAndToCreateOneYouNeedToMakeATransaction.asMarkdown())
                    
                    WLCard {
                        BEHStack(alignment: .center) {
                            UIImageView(width: 44, height: 44, image: .squircleSolanaIcon)
                            BEVStack {
                                BEHStack {
                                    UILabel(text: L10n.accountCreationFee, textSize: 13, textColor: .secondaryLabel)
                                    UILabel(text: "~0.5$", textSize: 13)
                                }
                                UILabel(text: "0.509 USDC", textSize: 17, weight: .semibold)
                            }.padding(.init(only: .left, inset: 12))
                            UIView.defaultNextArrow()
                        }.padding(.init(x: 18, y: 14))
                    }

                    ReceiveToken.textBuilder(text: L10n.minimumTransactionAmountOf("0.000112 BTC").asMarkdown())
                    ReceiveToken.textBuilder(text: L10n.isTheRemainingTimeToSafelySendTheAssets("35:59:59").asMarkdown())
                }.padding(.init(x: 18, y: 0))
                
                // Accept button
                WLStepButton.main(text: L10n.topUpYourAccount)
                    .onTap { [unowned self] in
                        self.viewModel.createRenBTCWallet()
                        self.back()
                        self.onCompletion?()
                    }
                    .padding(.init(x: 18, y: 36))
            }
        }
    }
}
