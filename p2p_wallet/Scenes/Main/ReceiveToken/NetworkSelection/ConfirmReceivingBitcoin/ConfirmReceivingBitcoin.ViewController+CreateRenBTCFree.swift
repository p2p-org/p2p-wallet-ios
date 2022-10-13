//
//  ConfirmReceivingBitcoin.ViewController+CreateRenBTCFree.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/10/2022.
//

import Foundation
import RxCocoa
import RxSwift

extension ConfirmReceivingBitcoin.ViewController {
    func createRenBTCFreeView() -> BEVStack {
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

    func createRenBTCFreeButton() -> UIView {
        WLStepButton.main(image: .buttonBuy.withTintColor(.white), text: L10n.free)
            .onTap { [unowned self] in
                self.viewModel.createRenBTC()
            }
    }
}
