// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import SwiftUI
import UIKit

class RecoveryKitCoordinator: Coordinator<Void> {
    let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        super.init()
    }

    override func start() -> AnyPublisher<Void, Never> {
        let result = PassthroughSubject<Void, Never>()

        let vm = RecoveryKitViewModel()
        vm.coordinator.seedPhrase = { [weak navigationController] in
            let vm = SeedPhraseDetailViewModel()
            let vc = KeyAppHostingController(rootView: SeedPhraseDetailView(viewModel: vm))
            vc.title = L10n.seedPhraseDetails
            navigationController?.pushViewController(vc, animated: true)
        }

        let vc = KeyAppHostingController(rootView: RecoveryKitView(viewModel: vm))
        vc.title = L10n.walletProtection
        vc.hidesBottomBarWhenPushed = true
        vc.onClose = { result.send() }

        navigationController.pushViewController(vc, animated: true)

        return result.eraseToAnyPublisher()
    }
}
