// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import SwiftUI
import Send

enum SendResult {
    case sent(SendTransaction)
    case cancelled
}

class SendCoordinator: Coordinator<SendResult> {
    let rootViewController: UINavigationController
    let result = PassthroughSubject<SendResult, Never>()

    init(rootViewController: UINavigationController) {
        self.rootViewController = rootViewController
        super.init()
    }
    
    override func start() -> AnyPublisher<SendResult, Never> {
        // Setup view
        let vm = RecipientSearchViewModel()
        vm.coordinator.selectRecipientPublisher
            .sink { [weak self] (recipient: Recipient) in self?.openSendInput(recipient: recipient) }
            .store(in: &subscriptions)

        let view = RecipientSearchView(viewModel: vm)
        let vc = UIHostingController(rootView: view)

        // Push strategy
        rootViewController.pushViewController(vc, animated: true)

        vc.onClose = { [weak self] in
            self?.result.send(.cancelled)
        }

        // Back
        return result.prefix(1).eraseToAnyPublisher()
    }

    private func openSendInput(recipient: Recipient) {
        coordinate(to: SendInputCoordinator(recipient: recipient, navigationController: rootViewController))
            .sink { [weak self] result in
                switch result {
                case .sent(let transaction):
                    self?.result.send(.sent(transaction))
                case .cancelled:
                    break
                }
            }
            .store(in: &subscriptions)
    }
}
