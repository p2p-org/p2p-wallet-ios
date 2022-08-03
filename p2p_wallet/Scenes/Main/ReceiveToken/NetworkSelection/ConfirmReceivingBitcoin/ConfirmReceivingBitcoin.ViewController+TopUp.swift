//
//  ConfirmReceivingBitcoin.ViewController+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/04/2022.
//

import Foundation
import RxCocoa

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
        WLStepButton.main(image: .buttonBuy.withTintColor(.white), text: L10n.topUpYourAccount)
            .onTap { [unowned self] in
                self.dismiss(animated: true) {
                    self.viewModel.dismissAndTopUp()
                }
            }
    }

    func shareSolanaAddressButton() -> UIView {
        WLStepButton.sub(text: L10n.shareYourSolanaNetworkAddress)
            .onTap { [unowned self] in
                guard let item = viewModel.solanaPubkey else { return }
                let vc = UIActivityViewController(activityItems: [item], applicationActivities: nil)
                present(vc, animated: true, completion: nil)
            }
    }
}
