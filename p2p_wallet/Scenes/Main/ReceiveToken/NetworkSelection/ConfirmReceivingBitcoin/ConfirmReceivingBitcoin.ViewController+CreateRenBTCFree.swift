//
//  ConfirmReceivingBitcoin.ViewController+CreateRenBTCFree.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/10/2022.
//

import RxCocoa
import RxSwift
import UIKit
import KeyAppUI

extension ConfirmReceivingBitcoin.ViewController {
    func createRenBTCFreeView() -> BEVStack {
        BEVStack(spacing: 12) {
            ReceiveToken.textBuilder(
                text: L10n.YouReGoingToCreateAPublicBitcoinAddressThatWillBeValidForTheNext24Hours
                    .youStillCanHoldAndSendBitcoinWithoutRestrictions
                    .asMarkdown()
            )
            ReceiveToken.textBuilder(
                text: L10n.itSAOneTimeAddressSoIfYouSendMultipleTransactionsYourMoneyWillBeLost
                    .asMarkdown()
            )
        }
    }

    func createRenBTCFreeButton() -> UIView {
        TextButton(title: L10n.createAddress, style: .primary, size: .large)
            .onTap { [unowned self] in
                self.viewModel.createRenBTC()
            }
    }
}
