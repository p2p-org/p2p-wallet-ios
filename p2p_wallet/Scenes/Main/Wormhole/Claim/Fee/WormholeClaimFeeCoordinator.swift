//
//  WormholeClaimFeeCoordinator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 12.03.2023.
//

import Foundation

class WormholeClaimFeeCoordinator: SmartCoordinator<Void> {
    override func build() -> UIViewController {
        let view = WormholeClaimFee { [weak self] in
            self?.presentation.presentingViewController.dismiss(animated: true)
        }

        return BottomSheetController(rootView: view)
    }
}
