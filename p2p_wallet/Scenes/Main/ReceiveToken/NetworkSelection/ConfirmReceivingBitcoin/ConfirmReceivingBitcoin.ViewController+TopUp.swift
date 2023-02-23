//
//  ConfirmReceivingBitcoin.ViewController+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/04/2022.
//

import Foundation
import KeyAppUI

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
        TextButton(
            title: L10n.topUpYourAccount,
            style: .primary,
            size: .large,
            leading: .buttonBuy.withTintColor(.white)
        ).onTap { [unowned self] in
            self.dismiss(animated: true) {
                self.viewModel.dismissAndTopUp()
            }
        }
    }

    func shareSolanaAddressButton() -> UIView {
        TextButton(title: L10n.shareYourSolanaNetworkAddress, style: .ghost, size: .large)
            .onPressed { [unowned self] _ in
                guard let item = viewModel.solanaPubkey else { return }
                let vc = UIActivityViewController(activityItems: [item], applicationActivities: nil)
                present(vc, animated: true, completion: nil)
            }
    }
}
