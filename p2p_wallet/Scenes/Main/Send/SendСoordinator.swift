// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Send
import SwiftUI
import SolanaSwift

enum SendResult {
    case sent(SendTransaction)
    case cancelled
}

class SendCoordinator: Coordinator<SendResult> {
    let rootViewController: UINavigationController
    let preChosenWallet: Wallet?
    let hideTabBar: Bool
    let result = PassthroughSubject<SendResult, Never>()

    init(rootViewController: UINavigationController, preChosenWallet: Wallet?, hideTabBar: Bool = false) {
        self.rootViewController = rootViewController
        self.preChosenWallet = preChosenWallet
        self.hideTabBar = hideTabBar
        super.init()
    }

    override func start() -> AnyPublisher<SendResult, Never> {
        // Setup view
        let vm = RecipientSearchViewModel(preChosenWallet: preChosenWallet)
        vm.coordinator.selectRecipientPublisher
            .flatMap { [unowned self] in
                self.coordinate(to: SendInputCoordinator(
                    recipient: $0,
                    preChosenWallet: preChosenWallet,
                    navigationController: rootViewController
                ))
            }
            .sink { [weak self] result in
                switch result {
                case let .sent(transaction):
                    self?.result.send(.sent(transaction))
                case .cancelled:
                    break
                }
            }
            .store(in: &subscriptions)

        vm.coordinator.scanQRPublisher
            .flatMap { [unowned self] in
                self.coordinate(to: ScanQrCoordinator(navigationController: rootViewController))
            }
            .compactMap { $0 }
            .sink(receiveValue: { result in
                Task { await vm.search(query: result, autoSelect: true) }
            }).store(in: &subscriptions)

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
