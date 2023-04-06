//
//  File.swift
//
//
//  Created by Giang Long Tran on 05.04.2023.
//

import Combine
import FeeRelayerSwift
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import SolanaSwift

public class WormholeSendUserActionConsumer: UserActionConsumer {
    public typealias Action = WormholeSendUserAction

    static let table = "WormholeSendUserActionConsumer"

    let signer: () -> KeyPair?

    let solanaClient: SolanaAPIClient

    let relayService: RelayService

    let errorObserver: ErrorObserver

    public let persistence: UserActionPersistentStorage

    public let onUpdate: PassthroughSubject<UserAction, Never> = .init()

    public init(
        signer: @escaping () -> KeyPair?,
        solanaClient: SolanaAPIClient,
        relayService: RelayService,
        errorObserver: ErrorObserver,
        persistence: UserActionPersistentStorage
    ) {
        self.signer = signer
        self.solanaClient = solanaClient
        self.relayService = relayService
        self.errorObserver = errorObserver
        self.persistence = persistence
    }

    public func start() {
        // Restore last running.
        Task {
            do {
                let userActions: [Action] = try await persistence.query(in: Self.table, type: Action.self)
                for userAction in userActions {
                    self.process(action: userAction)
                }
            } catch {
                errorObserver.handleError(error)
            }
        }
    }

    public func process(action: UserAction) {
        Task {
            guard var action = action as? Action else { return }

            onUpdate.send(action)

            var running: Bool = true
            while running {
                switch action.status {
                case .pending:
                    action = await onPending(action: action)

                case .processing:
                    action = await onProcessing(action: action)

                case .ready:
                    running = false

                case let .error(error):
                    errorObserver.handleError(error)
                    running = false
                }

                // Save state
                do {
                    switch action.status {
                    case .ready, .error:
                        if Date().timeIntervalSince(action.createdDate) > 60 * 2 {
                            try await persistence.delete(in: Self.table, userAction: action)
                        } else {
                            try await persistence.insert(in: Self.table, userAction: action)
                        }
                    default:
                        try await persistence.insert(in: Self.table, userAction: action)
                    }
                } catch {
                    errorObserver.handleError(error)
                }

                // Emit changes
                onUpdate.send(action)
            }
        }
    }

    /// Prepare signing and sending to blockchain.
    func onPending(action: Action) async -> Action {
        var action = action

        defer {
            action.updatedDate = Date()
        }

        /// Network fee in Solana network.
        let transactionFee: CryptoAmount = [action.fees.networkFee, action.fees.bridgeFee]
            .compactMap { $0 }
            .map(\.asCryptoAmount)
            .reduce(CryptoAmount(token: SolanaToken.nativeSolana), +)

        /// Account creation fee in Solana network.
        let accountCreationFee = action.fees.messageAccountRent?
            .asCryptoAmount ?? CryptoAmount(token: SolanaToken.nativeSolana)

        do {
            /// Top up user relay account.
            let topUpTransactions = try await relayService.topUp(
                amount: .init(
                    transaction: UInt64(transactionFee.value),
                    accountBalances: UInt64(accountCreationFee.value)
                ),
                payingFeeToken: action.payingFeeTokenAccount,
                relayContext: action.relayContext
            )

            /// Waiting confirmation on top up
            if let topUpTransactions {
                for topUpTransaction in topUpTransactions {
                    try await solanaClient.waitForConfirmation(signature: topUpTransaction, ignoreStatus: false)
                }
            }
        } catch {
            errorObserver.handleError(error)
            action.status = .error(.topUpFailure)
            return action
        }

        guard
            let data = Data(base64Encoded: action.transaction.transaction, options: .ignoreUnknownCharacters),
            var versionedTransaction = try? VersionedTransaction.deserialize(data: data),
            let configs = RequestConfiguration(encoding: "base64"),
            let signer = signer()
        else {
            action.status = .error(.init(domain: "WormholeSend", code: 1, reason: "Can not read transaction"))
            return action
        }

        do {
            // User signs transaction
            try versionedTransaction.sign(signers: [signer])

            // Relay service sign transacion
            // TODO: extract first n required signers for safety.
            if versionedTransaction.message.value.staticAccountKeys.contains(action.relayContext.feePayerAddress) {
                let fullySignedTransaction = try await relayService.signTransaction(
                    transactions: [versionedTransaction],
                    config: .init(operationType: .other)
                ).first

                guard let fullySignedTransaction else {
                    action
                        .status =
                        .error(.init(domain: "WormholeSend", code: 2, reason: "Fee relay signing failure"))
                    return action
                }

                versionedTransaction = fullySignedTransaction
            }

            // Submit transaction
            let encodedTrx = try versionedTransaction.serialize().base64EncodedString()
            _ = try await solanaClient.sendTransaction(transaction: encodedTrx, configs: configs)

            action.status = .processing
        } catch {
            action
                .status = .error(
                    .init(
                        domain: "WormholeSend",
                        code: 3,
                        reason: "Sending transaction to blockchain failure"
                    )
                )
            
            debugPrint(error)
            return action
        }

        return action
    }

    func onProcessing(action: Action) async -> Action {
        var action = action

        // TODO: Waiting on backend.
        if Date().timeIntervalSince(action.updatedDate) > 60 * 10 {
            action.status = .ready
        } else {
            try? await Task.sleep(seconds: 10)
        }

        return action
    }
}
