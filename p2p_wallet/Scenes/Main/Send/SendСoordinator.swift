// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import FeeRelayerSwift
import Foundation
import Resolver
import Send
import SolanaSwift
import SwiftUI

enum SendResult {
    case sent(SendTransaction)
    case wormhole(PendingTransaction)
    case cancelled
}

enum SendSource: String {
    case sell, none
}

class SendCoordinator: Coordinator<SendResult> {
    // MARK: - Dependencies

    @Injected var walletsRepository: WalletsRepository

    // MARK: - Properties

    let rootViewController: UINavigationController
    let hideTabBar: Bool
    let result = PassthroughSubject<SendResult, Never>()

    private let source: SendSource
    let preChosenWallet: Wallet?
    let preChosenRecipient: Recipient?
    let preChosenAmount: Double?
    let allowSwitchingMainAmountType: Bool

    // MARK: - Initializer

    init(
        rootViewController: UINavigationController,
        preChosenWallet: Wallet?,
        preChosenRecipient: Recipient? = nil,
        preChosenAmount: Double? = nil,
        hideTabBar: Bool = false,
        source: SendSource = .none,
        allowSwitchingMainAmountType: Bool
    ) {
        self.rootViewController = rootViewController
        self.preChosenWallet = preChosenWallet
        self.preChosenRecipient = preChosenRecipient
        self.preChosenAmount = preChosenAmount
        self.hideTabBar = hideTabBar
        self.source = source
        self.allowSwitchingMainAmountType = allowSwitchingMainAmountType
        super.init()
    }

    // MARK: - Methods

    override func start() -> AnyPublisher<SendResult, Never> {
        if walletsRepository.state == .loaded {
            let fiatAmount = walletsRepository.getWallets().reduce(0) { $0 + $1.amountInCurrentFiat }
            let withTokens = fiatAmount > 0
            if withTokens {
                // normal flow with no preChosenRecipient
                if let recipient = preChosenRecipient {
                    return startFlowWithPreChosenRecipient(recipient)
                } else {
                    startFlowWithNoPreChosenRecipient()
                }
            } else {
                showEmptyState()
            }

        } else {
            // Show not ready
            rootViewController.showAlert(title: L10n.TheDataIsBeingUpdated.pleaseTryAgainInAFewMinutes, message: nil)
            result.send(completion: .finished)
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
            source: source,
            pushedWithoutRecipientSearchView: true,
            allowSwitchingMainAmountType: allowSwitchingMainAmountType
        ))
    }

    private func startFlowWithNoPreChosenRecipient() {
        // Setup view
        let vm = RecipientSearchViewModel(preChosenWallet: preChosenWallet, source: source)
        vm.coordinator.selectRecipientPublisher
            .filter { $0.category != .ethereumAddress }
            .flatMap { [unowned self] in
                self.coordinate(to: SendInputCoordinator(
                    recipient: $0,
                    preChosenWallet: preChosenWallet,
                    preChosenAmount: preChosenAmount,
                    navigationController: rootViewController,
                    source: source,
                    allowSwitchingMainAmountType: allowSwitchingMainAmountType
                ))
            }
            .sink { [weak self] result in
                switch result {
                case let .sent(transaction):
                    self?.result.send(.sent(transaction))
                case let .wormhole(transaction):
                    self?.result.send(.wormhole(transaction))
                case .cancelled:
                    break
                }
            }
            .store(in: &subscriptions)

        vm.coordinator.selectRecipientPublisher
            .filter { $0.category == .ethereumAddress }
            .flatMap { [unowned self] in
                self.coordinate(
                    to: WormholeSendInputCoordinator(recipient: $0, from: rootViewController)
                )
            }
            .sink { [weak self] result in
                switch result {
                case let .transaction(transaction):
                    self?.result.send(.wormhole(transaction))
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

        Task {
            await vm.load()
        }

        let view = RecipientSearchView(viewModel: vm)
        let vc = KeyboardAvoidingViewController(rootView: view, navigationBarVisibility: .visible)
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.navigationItem.setTitle(L10n.chooseARecipient, subtitle: "Solana network")
        vc.hidesBottomBarWhenPushed = hideTabBar

        // Push strategy
        rootViewController.pushViewController(vc, animated: true)

        vc.onClose = { [weak self] in
            self?.result.send(.cancelled)
        }
    }

    private func showEmptyState() {
        let coordinator = SendEmptyCoordinator(navigationController: rootViewController)
        coordinator.start()
            .sink(receiveValue: { [weak self] _ in self?.result.send(completion: .finished) })
            .store(in: &subscriptions)
    }
}
