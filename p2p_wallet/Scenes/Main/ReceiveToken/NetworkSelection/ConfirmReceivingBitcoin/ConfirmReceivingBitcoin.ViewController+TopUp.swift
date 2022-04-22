//
//  ConfirmReceivingBitcoin.ViewController+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/04/2022.
//

import Foundation
import RxCocoa
import RxSwift

extension ConfirmReceivingBitcoin.ViewController {
    func topUpRequiredView() -> BEVStack {
        BEVStack(spacing: 12) {
            ReceiveToken.textBuilder(
                text: L10n.aToReceiveBitcoinsOverTheBitcoinNetwork(L10n.renBTCAccountIsRequired)
                    .asMarkdown()
            )
            ReceiveToken.textBuilder(
                text: L10n.yourWalletListDoesNotContainARenBTCAccountAndToCreateOne(L10n
                    .youNeedToMakeATransaction)
                    .asMarkdown()
            )
            ReceiveToken.textBuilder(
                text: L10n.youToPayForAccountCreationButIfSomeoneSendsRenBTCToYourAddressItWillBeCreatedForYou(L10n
                    .donTHaveFunds)
                    .asMarkdown()
            )
        }
    }

    func topUpButtonsView() -> UIView {
        WLStepButton.main(image: .add, text: L10n.topUpYourAccount)
    }

    func shareSolanaAddressButton() -> UIView {
        WLStepButton.sub(text: L10n.shareYourSolanaNetworkAddress)
    }
}
