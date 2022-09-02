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
        vm.seedPhrase = { [weak navigationController] in
            let vm = SeedPhraseDetailViewModel()
            let vc = UIHostingController(rootView: SeedPhraseDetailView(viewModel: vm))
            navigationController?.pushViewController(vc, animated: true)
        }

        let vc = UIHostingController(rootView: RecoveryKitView(viewModel: vm))
        vc.onClose = { result.send() }

        navigationController.pushViewController(vc, animated: true)

        return result.eraseToAnyPublisher()
    }
}
