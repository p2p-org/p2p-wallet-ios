// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import FeeRelayerSwift
import Foundation
import Resolver
import Send
import SolanaSwift
import Send
import SwiftUI

enum SendResult {
    case sent(SendTransaction)
    case cancelled
}

enum SendSource: String {
    case sell, none
}

class SendCoordinator: Coordinator<SendResult> {

    // MARK: - Properties

    let rootViewController: UINavigationController
    let hideTabBar: Bool
    let result = PassthroughSubject<SendResult, Never>()

    private let source: SendSource
    let preChosenWallet: Wallet?
    let preChosenRecipient: Recipient?
    let preChosenAmount: Double?

    // MARK: - Initializer

    init(
        rootViewController: UINavigationController,
        preChosenWallet: Wallet?,
        preChosenRecipient: Recipient? = nil,
        preChosenAmount: Double? = nil,
        hideTabBar: Bool = false,
        source: SendSource = .none
    ) {
        self.rootViewController = rootViewController
        self.preChosenWallet = preChosenWallet
        self.preChosenRecipient = preChosenRecipient
        self.preChosenAmount = preChosenAmount
        self.hideTabBar = hideTabBar
        self.source = source
        super.init()
    }

    // MARK: - Methods

    override func start() -> AnyPublisher<SendResult, Never> {
        // Pre warm
        Task.detached {
            try await Resolver.resolve(FeeRelayerContextManager.self).update()
        }

        // normal flow with no preChosenRecipient
        if let recipient = preChosenRecipient {
            return startFlowWithPreChosenRecipient(recipient)
        } else {
            startFlowWithNoPreChosenRecipient()
        }

        // Back
        return result.prefix(1).eraseToAnyPublisher()
    }
    
    // MARK: - Helpers
    
    private func startFlowWithPreChosenRecipient(
        _ recipient: Recipient
    ) -> AnyPublisher<SendResult, Never> {
        coordinate(to: SendInputCoordinator(
            recipient: recipient,
            preChosenWallet: preChosenWallet,
            preChosenAmount: preChosenAmount,
            navigationController: rootViewController,
            source: source
        ))
    }

    private func startFlowWithNoPreChosenRecipient() {
        let vm = RecipientSearchViewModel(preChosenWallet: preChosenWallet, source: source)
        vm.coordinator.selectRecipientPublisher
            .flatMap { [unowned self] in
                self.coordinate(to: SendInputCoordinator(
                    recipient: $0,
                    preChosenWallet: preChosenWallet,
                    preChosenAmount: preChosenAmount,
                    navigationController: rootViewController,
                    source: source
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
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak vm] result in
                vm?.searchQR(query: result, autoSelectTheOnlyOneResultMode: .enabled(delay: 0))
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
