//
//  NetworkSelection.ViewController.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 14.12.21.
//
//

import UIKit
import RxSwift
import RxCocoa
import BEPureLayout

extension ReceiveToken {
    class BitcoinConfirmScene: WLBottomSheet {
        let onCompletion: (() -> Void)?
        let viewModel: ReceiveTokenBitcoinViewModelType
        
        init(viewModel: ReceiveTokenBitcoinViewModelType, onCompletion: (() -> Void)? = nil) {
            self.onCompletion = onCompletion
            self.viewModel = viewModel
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
                
                // Description
                UIStackView(axis: .vertical, spacing: 12, alignment: .fill) {
                    ReceiveToken.textBuilder(text: L10n.ThisAddressAcceptsOnly.youMayLoseAssetsBySendingAnotherCoin(L10n.bitcoin).asMarkdown())
                    ReceiveToken.textBuilder(text: L10n.minimumTransactionAmountOf("0.000112 BTC").asMarkdown())
                    ReceiveToken.textBuilder(text: L10n.isTheRemainingTimeToSafelySendTheAssets("35:59:59").asMarkdown())
                }.padding(.init(x: 18, y: 0))
                
                // Accept button
                WLStepButton.main(image: .check.withTintColor(.white), text: L10n.iUnderstand)
                    .padding(.init(only: .top, inset: 36))
                    .onTap { [unowned self] in
                        self.viewModel.acceptConditionAndLoadAddress()
                        self.back()
                        self.onCompletion?()
                    }
                    .padding(.init(x: 18, y: 4))
            }
        }
    }
}
