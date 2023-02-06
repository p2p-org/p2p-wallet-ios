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

enum SendArgs {
    case `default`
    case wallet(Wallet)
    case fixed(wallet: Wallet, recipient: Recipient, amount: Double)
}

final class SendCoordinator: Coordinator<SendResult> {
    
    // MARK: - Dependencies

    @Injected private var walletsRepository: WalletsRepository

    // MARK: - Properties

    private let rootViewController: UINavigationController
    private let result = PassthroughSubject<SendResult, Never>()

    private let source: SendSource
    private let allowSwitchingMainAmountType: Bool
    private let args: SendArgs

    // MARK: - Initializer

    init(
        rootViewController: UINavigationController,
        args: SendArgs = .default,
        source: SendSource = .none,
        allowSwitchingMainAmountType: Bool
    ) {
        self.rootViewController = rootViewController
        self.args = args
        self.source = source
        self.allowSwitchingMainAmountType = allowSwitchingMainAmountType
        super.init()
    }

    // MARK: - Methods

    override func start() -> AnyPublisher<SendResult, Never> {
        if walletsRepository.currentState == .loaded {
            let fiatAmount = walletsRepository.getWallets().reduce(0) { $0 + $1.amountInCurrentFiat }
            let withTokens = fiatAmount > 0
            if withTokens {
                switch args {
                case .default:
                    return openRecipientSearch(preChosenWallet: nil)
                case let .wallet(wallet):
                    return openRecipientSearch(preChosenWallet: wallet)
                case let .fixed(wallet, recipient, amount):
                    return openSendInput(recipient: recipient, wallet: wallet, amount: amount)
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

    private func openSendInput(
        recipient: Recipient,
        wallet: Wallet,
        amount: Double
    ) -> AnyPublisher<SendResult, Never> {
        coordinate(to: SendInputCoordinator(
            parameters: SendInputParameters(
                source: source,
                recipient: recipient,
                preChosenWallet: wallet,
                preChosenAmount: amount,
                pushedWithoutRecipientSearchView: true,
                allowSwitchingMainAmountType: allowSwitchingMainAmountType
            ),
            navigationController: rootViewController
        ))
    }

    private func openRecipientSearch(preChosenWallet: Wallet?) -> AnyPublisher<SendResult, Never> {
        coordinate(to: RecipientSearchCoordinator(
            rootViewController: rootViewController,
            preChosenWallet: preChosenWallet,
            source: source,
            allowSwitchingMainAmountType: allowSwitchingMainAmountType
        ))
    }

    private func showEmptyState() {
        let coordinator = SendEmptyCoordinator(navigationController: rootViewController)
        coordinator.start()
            .sink(receiveValue: { [weak self] _ in self?.result.send(completion: .finished) })
            .store(in: &subscriptions)
    }
}
