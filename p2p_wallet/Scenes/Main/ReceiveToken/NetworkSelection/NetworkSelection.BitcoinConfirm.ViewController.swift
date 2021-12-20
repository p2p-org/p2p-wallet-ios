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

extension ReceiveToken {
    class BitcoinConfirmScene: WLBottomSheet {
        let onAccept: (() -> Void)?
        
        init(onAccept: (() -> Void)? = nil) {
            self.onAccept = onAccept
            super.init()
        }
        
        override var preferredNavigationBarStype: NavigationBarStyle { .hidden }
        
        override func build() -> UIView? {
            UIStackView(axis: .vertical, alignment: .fill) {
                
                UIStackView(axis: .vertical, alignment: .center) {
                    UILabel(text: L10n.receivingViaBitcoinNetwork, textSize: 20, weight: .semibold)
                        .padding(.init(only: .bottom, inset: 4))
                    UILabel(text: L10n.makeSureYouUnderstandTheAspects, textColor: .textSecondary)
                }
                
                UIStackView(axis: .vertical, alignment: .center) {
                    UIImageView(width: 44, height: 44, image: .squircleAlert)
                }.padding(.init(x: 0, y: 18))
                
                ReceiveToken.textBuilder(text: L10n.ThisAddressAccepts.youMayLoseAssetsBySendingAnotherCoin(L10n.onlyBitcoin))
                ReceiveToken.textBuilder(text: L10n.minimumTransactionAmountOf("0.000112 BTC"))
                ReceiveToken.textBuilder(text: L10n.isTheRemainingTimeToSafelySendTheAssets("35:59:59"))
                
                WLStepButton.main(image: .checkBoxIOS, text: L10n.iUnderstand)
                    .padding(.init(only: .top, inset: 36))
                    .onTap { [unowned self] in
                        self.back()
                        self.onAccept?()
                    }
            }.padding(.init(all: 18))
        }
    }
}
