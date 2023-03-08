//
//  SupportedTokenNetworksCoordinator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 09.03.2023.
//

import Foundation
import KeyAppUI
import SwiftUI

class SupportedTokenNetworksCoordinator: SmartCoordinator<SupportedTokenItemNetwork?> {
    let supportedToken: SupportedTokenItem

    init(supportedToken: SupportedTokenItem, viewController: UIViewController) {
        self.supportedToken = supportedToken
        super.init(presentation: SmartCoordinatorPresentPresentation(viewController))
    }

    override func build() -> UIViewController {
        let view = SupportedTokenNetworksView(item: supportedToken) { [weak self] network in
            self?.dismiss(network)
        }

        let vc = BottomSheetController(rootView: view)
        vc.view.backgroundColor = Asset.Colors.smoke.color

        return vc
    }
}
