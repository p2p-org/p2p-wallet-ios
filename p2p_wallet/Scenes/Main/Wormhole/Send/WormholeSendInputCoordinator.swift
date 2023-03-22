//
//  WormhyoleSendInputCoordinator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 22.03.2023.
//

import Foundation
import Send
import SwiftUI

class WormholeSendInputCoordinator: SmartCoordinator<String> {
    let recipient: Recipient

    init(recipient: Recipient, from: UINavigationController) {
        self.recipient = recipient
        super.init(presentation: SmartCoordinatorPushPresentation(from))
    }

    override func build() -> UIViewController {
        let viewModel = WormholeSendInputViewModel(recipient: recipient)
        let view = WormholeSendInputView(viewModel: viewModel)

        return UIHostingController(rootView: view)
    }
}
