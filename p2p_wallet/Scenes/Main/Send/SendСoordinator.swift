// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Send
import SwiftUI

enum SendResult {
    case sent(SendTransaction)
    case cancelled
}

class SendCoordinator: Coordinator<SendResult> {
    let rootViewController: UINavigationController
    let hideTabBar: Bool

    let result = PassthroughSubject<SendResult, Never>()

    init(rootViewController: UINavigationController, hideTabBar: Bool = false) {
        self.rootViewController = rootViewController
        self.hideTabBar = hideTabBar
        super.init()
    }

    override func start() -> AnyPublisher<SendResult, Never> {
        // Setup view
        let vm = RecipientSearchViewModel()
        vm.coordinator.selectRecipientPublisher
            .sink { [weak self] (recipient: Recipient) in self?.openSendInput(recipient: recipient) }
            .store(in: &subscriptions)

        let view = RecipientSearchView(viewModel: vm)
        let vc = KeyboardAvoidingViewController(rootView: view)
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.navigationItem.setTitle(L10n.chooseARecipient, subtitle: "Solana network")
        vc.hidesBottomBarWhenPushed = hideTabBar

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
                case let .sent(transaction):
                    self?.result.send(.sent(transaction))
                case .cancelled:
                    break
                }
            }
            .store(in: &subscriptions)
    }
}

class CustomUIHostingController<Content: View>: UIHostingController<Content> {
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if #available(iOS 15.0, *) {
            //  Workaround for an iOS 15 SwiftUI bug(?):
            //  The intrinsicContentSize of UIView is not updated
            //  when the internal SwiftUI view changes size.

            view.invalidateIntrinsicContentSize()
        }
    }
}
